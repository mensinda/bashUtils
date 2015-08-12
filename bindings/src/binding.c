#include "binding.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <pthread.h>

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

  size_t numFuncs;

  struct bindingFUNC *begin;
  struct bindingFUNC *end;

  bindingFunctionPTR *funcs;
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

  s->numFuncs = 0;

  s->begin = NULL;
  s->end = NULL;

  s->funcs = NULL;

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

  if ( _s->data != NULL && _s->length > 0 )
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

  _inf->funcs = malloc( sizeof( bindingFunctionPTR ) * _inf->numFuncs );
  struct bindingFUNC *curr = _inf->begin;

  size_t s;
  int c;
  for ( int i = 0; i < _inf->numFuncs; i++ ) {
    if ( curr == NULL ) {
      printf( "binding: ERROR: internal init Error: bindingFUNC is NULL when it should not!\n" );
      return -1;
    }

    s = snprintf( NULL, 0, "%s:%lu,%lu", curr->name, curr->in, curr->out );
    fprintf( _inf->sCall, "I%lu;%s:%lu,%lu", s, curr->name, curr->in, curr->out );
    fflush( _inf->sCall );

    c = fgetc( _inf->sReturn );
    if ( c != '1' ) {
      printf( "binding: ERROR: failed to init: missing BASH binding '%s'\n", curr->name );
      return -2;
    }

    _inf->funcs[i] = curr->fPTR;

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
 * Reads a char from _file and exists if EOF
 */
int readChar( FILE *_file ) {
  int c = fgetc( _file );
  if ( c == EOF )
    pthread_exit( NULL );

  return c;
}

void *readCALL_thread( void *_d ) {
  struct bindingINFO *inf = (struct bindingINFO *)_d;
  int c;
  while ( 1 ) {
    c = readChar( inf->bCall );
    switch ( c ) {
      case 'E':
        fprintf( inf->bReturn, "E" );
        fflush( inf->bReturn );
        pthread_exit( NULL );
        break;
      default: printf( "binding: WARNING: -- RETURN -- Unknown command '%c'\n", c );
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
  pthread_t readCALL;
  pthread_t bbind_readReturn;
  pthread_attr_t attr;

  pthread_attr_init( &attr );
  pthread_attr_setdetachstate( &attr, PTHREAD_CREATE_JOINABLE );

  int ret;
  ret = pthread_create( &readCALL, &attr, readCALL_thread, (void *)_inf );
  if ( ret != 0 ) {
    printf( "binding: ERROR: Failed to create thread 1\n" );
    return 1;
  }
  ret = pthread_create( &bbind_readReturn, &attr, bbind_readReturn_thread, (void *)_inf );
  if ( ret != 0 ) {
    printf( "binding: ERROR: Failed to create thread 2\n" );
    return 2;
  }

  pthread_attr_destroy( &attr );

  pthread_join( readCALL, NULL );
  pthread_join( bbind_readReturn, NULL );

  fclose( _inf->bCall );
  fclose( _inf->bReturn );
  fclose( _inf->sCall );
  fclose( _inf->sReturn );

  bbind_freeINFO( _inf );
  return 0;
}
