#include "binding.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>

struct bindingINFO {
  FILE *bCall;
  FILE *bReturn;
  FILE *sCall;
  FILE *sReturn;

  unsigned int funcCounter;
};

struct bindingINFO *bbind_newINFO() {
  struct bindingINFO *s = malloc( sizeof( struct bindingINFO ) );

  s->bCall = NULL;
  s->bReturn = NULL;
  s->sCall = NULL;
  s->sReturn = NULL;

  s->funcCounter = 0;

  return s;
}

struct bindingCALL *bbind_newCALL() {
  struct bindingCALL *s = malloc( sizeof( struct bindingCALL ) );
  s->next = NULL;
  s->data = NULL;
  return s;
}

void bbind_freeINFO( struct bindingINFO *_s ) {
  if ( _s != NULL )
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


int bbind_addFunction( struct bindingINFO *_inf,
                       bindingFunctionPTR ptr,
                       char const *_name,
                       char const *_params ) {
  if ( _inf == NULL )
    return 1;

  return 0;
}


int openFIFO( char const *_root, char const *_name, FILE **_f ) {
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

  *_f = fopen( path, "r+" );
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

  ret += openFIFO( _dir, FIFO_NAMES[0], &_inf->bCall );
  ret += openFIFO( _dir, FIFO_NAMES[1], &_inf->bReturn );
  ret += openFIFO( _dir, FIFO_NAMES[2], &_inf->sCall );
  ret += openFIFO( _dir, FIFO_NAMES[3], &_inf->sReturn );

  return ret;
}

int bbind_end( struct bindingINFO *_inf ) {
  fclose( _inf->bCall );
  fclose( _inf->bReturn );
  fclose( _inf->sCall );
  fclose( _inf->sReturn );

  bbind_freeINFO( _inf );
  return 0;
}
