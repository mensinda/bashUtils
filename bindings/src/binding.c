#include "binding.h"
#include "tidVector.h"
#include "utils.h"

#include <libtcc.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>

/*
 *    _____ _                   _
 *   /  ___| |                 | |
 *   \ `--.| |_ _ __ _   _  ___| |_ ___
 *    `--. \ __| '__| | | |/ __| __/ __|
 *   /\__/ / |_| |  | |_| | (__| |_\__ \
 *   \____/ \__|_|   \__,_|\___|\__|___/
 *
 */


struct bindingINFO {
  FILE *bCall;
  FILE *bReturn;
  FILE *sCall;
  FILE *sReturn;

  struct tidVector *threads;

  size_t numFuncs;

  struct bindingFUNC *begin;
  struct bindingFUNC *end;

  struct bindingFUNC **funcs;

  struct TCCState *tcc;
  void *tcc_mem;
};

struct bindingFUNC {
  char *name;

  bindingFunctionPTR fPTR;

  size_t in;
  size_t out;

  struct bindingFUNC *next;
};

struct bindingINFO *bbind_newINFO() {
  struct bindingINFO *s = malloc( sizeof( struct bindingINFO ) );

  s->bCall = NULL;
  s->bReturn = NULL;
  s->sCall = NULL;
  s->sReturn = NULL;

  s->threads = tid_init();

  s->numFuncs = 0;

  s->begin = NULL;
  s->end = NULL;

  s->funcs = NULL;

  s->tcc = tcc_new();
  tcc_set_output_type( s->tcc, TCC_OUTPUT_MEMORY );

  s->tcc_mem = NULL;

  return s;
}

struct bindingFUNC *bbind_newFUNC() {
  struct bindingFUNC *s = malloc( sizeof( struct bindingFUNC ) );

  s->name = NULL;
  s->fPTR = NULL;
  s->next = NULL;

  s->in = 0;
  s->out = 0;

  return s;
}

struct bindingCALL *bbind_newCALL() {
  struct bindingCALL *s = malloc( sizeof( struct bindingCALL ) );
  s->next = NULL;
  s->data = NULL;
  return s;
}

void bbind_freeINFO( struct bindingINFO *_s ) {
  if ( _s == NULL )
    return;

  if ( _s->begin != 0 )
    bbind_freeFUNC( _s->begin );

  if ( _s->funcs != NULL )
    free( _s->funcs );

  if ( _s->threads != NULL )
    tid_free( _s->threads );

  tcc_delete( _s->tcc );

  if ( _s->tcc_mem != NULL )
    free( _s->tcc_mem );

  free( _s );
}

void bbind_freeFUNC( struct bindingFUNC *_s ) {
  if ( _s == NULL )
    return;

  if ( _s->name != NULL )
    free( _s->name );

  if ( _s->next != NULL )
    bbind_freeFUNC( _s->next );

  free( _s );
}

void bbind_freeCALL( struct bindingCALL *_s ) {
  if ( _s == NULL )
    return;

  if ( _s->data != NULL && _s->length > 0 && _s->isPTR != '1' )
    free( _s->data );

  if ( _s->next != NULL )
    bbind_freeCALL( _s->next );

  free( _s );
}

/*
 *    _____      _ _
 *   |_   _|    (_) |
 *     | | _ __  _| |_
 *     | || '_ \| | __|
 *    _| || | | | | |_
 *    \___/_| |_|_|\__|
 *
 */


int bbind_addFunction( struct bindingINFO *_inf,
                       bindingFunctionPTR ptr,
                       char const *_name,
                       size_t _params,
                       size_t _return ) {
  if ( _inf == NULL )
    return 1;

  _inf->numFuncs++;

  struct bindingFUNC *current = bbind_newFUNC();
  current->name = malloc( strlen( _name ) * sizeof( char ) );
  strcpy( current->name, _name );

  current->fPTR = ptr;
  current->in = _params;
  current->out = _return;

  if ( _inf->begin == NULL ) {
    _inf->begin = current;
  }

  if ( _inf->end != NULL ) {
    _inf->end->next = current;
  }
  _inf->end = current;

  return 0;
}

int bbind_addCallback( struct bindingINFO *_inf, char const *_name, void *_val ) {
  tcc_add_symbol( _inf->tcc, _name, _val );
  return 0;
}


int openFIFO( char const *_root, char const *_mode, char const *_name, FILE **_f ) {
  char *path = malloc( ( strlen( _root ) + strlen( _name ) + 3 ) * sizeof( char ) );

  strcpy( path, _root );
  strcat( path, "/" );
  strcat( path, _name );

  struct stat st;
  if ( stat( path, &st ) == -1 ) {
    printf( "binding: ERROR: can not access '%s'\n", path );
    free( path );
    return 1;
  }
  if ( !S_ISFIFO( st.st_mode ) ) {
    printf( "binding: ERROR: '%s' is NOT a FIFO\n", path );
    free( path );
    return 2;
  }

  *_f = fopen( path, _mode );
  if ( *_f == NULL ) {
    printf( "binding: ERROR: Failed to open FIFO '%s'\n", path );
    free( path );
    return 3;
  }

  free( path );
  return 0;
}

int bbind_init( struct bindingINFO *_inf, char const *_dir ) {
  int ret = 0;

  ret += openFIFO( _dir, "r", "bindingCALL", &_inf->bCall );
  ret += openFIFO( _dir, "r", "shellRETURN", &_inf->sReturn );
  ret += openFIFO( _dir, "w", "bindingRETURN", &_inf->bReturn );
  ret += openFIFO( _dir, "w", "shellCALL", &_inf->sCall );

  _inf->funcs = malloc( sizeof( struct bindingFUNC * ) * _inf->numFuncs );
  struct bindingFUNC *curr = _inf->begin;

  size_t s;
  int c;
  for ( int i = 0; i < _inf->numFuncs; i++ ) {
    if ( curr == NULL ) {
      printf( "binding: ERROR: internal init Error: bindingFUNC is NULL when it should not!\n" );
      return -1;
    }

    s = snprintf( NULL, 0, "%s#%i:%lu,%lu", curr->name, i, curr->in, curr->out );
    fprintf( _inf->sCall, "I%lu;%s#%i:%lu,%lu", s, curr->name, i, curr->in, curr->out );
    fflush( _inf->sCall );

    c = fgetc( _inf->sReturn );
    if ( c != '1' ) {
      printf( "binding: ERROR: failed to init: missing BASH binding '%s'\n", curr->name );
      return -2;
    }

    _inf->funcs[i] = curr;

    curr = curr->next;
  }

  fprintf( _inf->sCall, "i0;" ); /* Done init */
  fflush( _inf->sCall );

  return ret;
}

/*
 *   ______                  _
 *   | ___ \                (_)
 *   | |_/ /   _ _ __  _ __  _ _ __   __ _
 *   |    / | | | '_ \| '_ \| | '_ \ / _` |
 *   | |\ \ |_| | | | | | | | | | | | (_| |
 *   \_| \_\__,_|_| |_|_| |_|_|_| |_|\__, |
 *                                    __/ |
 *                                   |___/
 */

/*
 * Call string format
 * <fn INDEX>|<metadata size>;<metadata><arg1 isPTR>,<arg1 length>:<arg1>
 */
void *processCALL( void *_d ) {
  struct stringAndInfPtr *data = (struct stringAndInfPtr *)_d;
  if ( data == NULL )
    pthread_exit( NULL );

  unsigned long int fID, metadataSize, stringLength, argSize;
  char isPTR;

  stringLength = strlen( data->str );
  char *worker = data->str;

  worker = getNextNum( worker, '|', &fID );
  worker = getNextNum( worker, ';', &metadataSize );

  if ( worker == NULL ) {
    printf( "binding: ERROR: Invalid call string\n" );
    goto cleanup_partial;
  }

  if ( fID >= data->inf->numFuncs ) {
    printf( "binding: ERROR: Invalid function index %lu\n", fID );
    goto cleanup_partial;
  }

  if ( stringLength - ( worker - data->str ) < metadataSize ) {
    printf( "binding: ERROR: Invalid metadata size %lu\n", metadataSize );
    goto cleanup_partial;
  }

  char *metadata = malloc( ( metadataSize + 1 ) * sizeof( char ) );
  memcpy( (void *)metadata, (void *)worker, metadataSize );
  metadata[metadataSize] = '\0';
  worker += metadataSize;

  struct bindingCALL *out = NULL;
  struct bindingCALL *in = bbind_newCALL();
  struct bindingCALL *inWorker = in;

  for ( size_t i = 0; ( worker - data->str ) < stringLength; i++ ) {
    isPTR = *worker;
    worker += 2;
    worker = getNextNum( worker, ':', &argSize );

    if ( worker == NULL ) {
      printf( "binding: ERROR: Invalid parameter string! (arg%lu)\n", i );
      goto cleanup;
    }

    if ( stringLength - ( worker - data->str ) < argSize ) {
      printf( "binding: ERROR: Invalid argSize size %lu at arg %lu\n", argSize, i );
      goto cleanup;
    }

    inWorker->isPTR = isPTR;
    inWorker->length = argSize;
    if ( isPTR == '0' ) {
      inWorker->data = malloc( ( argSize + 1 ) * sizeof( char ) );

      memcpy( (void *)inWorker->data, (void *)worker, argSize );
      inWorker->data[argSize] = '\0';

    } else if ( isPTR == '1' ) {
      inWorker->length = 0;
      char *temp = malloc( ( argSize + 1 ) * sizeof( char ) );
      memcpy( (void *)temp, (void *)worker, argSize );
      temp[argSize] = '\0';

      unsigned long int ptr = strtoul( temp, NULL, 10 );
      inWorker->data = (char *)ptr;

      free( temp );

    } else {
      printf( "binding: ERROR: Invalid ptr state '%c' at arg %lu\n", isPTR, i );
      goto cleanup;
    }

    worker += argSize;

    inWorker->next = bbind_newCALL();
    inWorker = inWorker->next;
  }

  if ( data->inf->funcs[fID]->fPTR( data->inf, in, &out ) != 0 ) {
    int bSize = snprintf( NULL, 0, "%lu|%lu;%sERROR", fID, metadataSize, metadata );
    fprintf( data->inf->bReturn, "R%i;%lu|%lu;%sERROR", bSize, fID, metadataSize, metadata );
    goto cleanup;
  }

  size_t outStrSize = 0;

  struct bindingCALL *outWorker = out;
  for ( size_t i = 0; outWorker != NULL; i++ ) {
    outStrSize += snprintf( NULL, 0, "%c,%lu:", outWorker->isPTR, outWorker->length );
    outStrSize += outWorker->length;
    outWorker = outWorker->next;
  }

  if ( outStrSize == 0 ) {
    int bSize = snprintf( NULL, 0, "%lu|%lu;%s", fID, metadataSize, metadata );
    fprintf( data->inf->bReturn, "R%i;%lu|%lu;%s", bSize, fID, metadataSize, metadata );
    goto cleanup;
  }

  outWorker = out;
  char *outStr = malloc( ( outStrSize + 1 ) * sizeof( char ) );
  char *outStrWorker = outStr;

  for ( size_t i = 0; outWorker != NULL; i++ ) {
    outStrWorker += snprintf( outStrWorker,
                              outStrSize - ( outStrWorker - outStr ) + 1,
                              "%c,%lu:",
                              outWorker->isPTR,
                              outWorker->length );

    outStrWorker += snprintf( outStrWorker, outWorker->length + 1, "%s", outWorker->data );
    outWorker = outWorker->next;
  }

  int bSize = snprintf( NULL, 0, "%lu|%lu;%s%s", fID, metadataSize, metadata, outStr );
  fprintf( data->inf->bReturn, "R%i;%lu|%lu;%s%s", bSize, fID, metadataSize, metadata, outStr );

  free( outStr );

cleanup:
  if ( out != NULL )
    bbind_freeCALL( out );

  bbind_freeCALL( in );
  free( metadata );

cleanup_partial:
  fflush( stdout );
  fflush( data->inf->bReturn );
  free_stringAndInfPtr( data );
  pthread_exit( NULL );
}


void *readCALL_thread( void *_d ) {
  struct bindingINFO *inf = (struct bindingINFO *)_d;
  int c, ret = 0;
  while ( 1 ) {
    c = readChar( inf->bCall );
    fflush( stdout );
    switch ( c ) {
      case 'C':
        ret = tid_create( inf->threads, &processCALL, (void *)readSizedInput( inf->bCall, inf ) );
        if ( ret != 0 )
          printf( "binding: ERROR: Failed to create internal call process thread!\n" );
        break;
      case 'E':
        fprintf( inf->bReturn, "E" );
        fflush( inf->bReturn );
        pthread_exit( NULL );
        break;
      default:
        printf( "binding: WARNING: -- RETURN -- Unknown command '%c'\n", c );
        fflush( stdout );
    }
  }
  pthread_exit( NULL );
}

void *bbind_readReturn_thread( void *_d ) {
  struct bindingINFO *inf = (struct bindingINFO *)_d;
  int c;
  while ( 1 ) {
    c = readChar( inf->sReturn );
    switch ( c ) {
      case 'E':
        fprintf( inf->sCall, "E" );
        fflush( inf->sCall );
        pthread_exit( NULL );
        break;
      default: printf( "binding: WARNING: -- RETURN -- Unknown command '%c'\n", c );
    }
  }
  pthread_exit( NULL );
}

int bbind_run( struct bindingINFO *_inf ) {
  int ret;
  ret = tid_create( _inf->threads, &readCALL_thread, (void *)_inf );
  if ( ret != 0 ) {
    printf( "binding: ERROR: Failed to create thread 1\n" );
    return 1;
  }
  ret = tid_create( _inf->threads, &bbind_readReturn_thread, (void *)_inf );
  if ( ret != 0 ) {
    printf( "binding: ERROR: Failed to create thread 2\n" );
    return 2;
  }

  tid_joinAll( _inf->threads );

  fclose( _inf->bCall );
  fclose( _inf->bReturn );
  fclose( _inf->sCall );
  fclose( _inf->sReturn );

  bbind_freeINFO( _inf );
  return 0;
}
