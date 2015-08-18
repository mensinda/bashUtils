#include "utils.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <limits.h>
#include <pthread.h>

struct stringAndInfPtr *new_stringAndInfPtr() {
  struct stringAndInfPtr *s = malloc( sizeof( struct stringAndInfPtr ) );
  s->inf = NULL;
  s->str = NULL;
  return s;
}

void free_stringAndInfPtr( struct stringAndInfPtr *_s ) {
  if ( _s == NULL )
    return;

  if ( _s->str != NULL )
    free( _s->str );

  free( _s );
}

/*
 * Reads a char from _file and exists if EOF
 */
int readChar( FILE *_file ) {
  int c = fgetc( _file );
  if ( c == EOF )
    pthread_exit( NULL );

  return c;
}

struct stringAndInfPtr *readSizedInput( FILE *_file, struct bindingINFO *_inf ) {
  char size[25];
  size_t i;
  for ( i = 0; i < 25; i++ ) {
    size[i] = readChar( _file );

    /* End of size num */
    if ( size[i] == ';' ) {
      size[i] = '\0';
      break;
    }

    if ( size[i] < '0' || size[i] > '9' )
      return NULL;
  }

  /* Num is to long for a unsigned 64 bit integer */
  if ( i >= 25 )
    return NULL;

  size_t s = strtoul( size, NULL, 10 );
  if ( s == ULONG_MAX )
    return NULL;

  struct stringAndInfPtr *data = new_stringAndInfPtr();
  data->inf = _inf;
  data->str = malloc( ( s + 1 ) * sizeof( char ) );

  for ( i = 0; i < s; i++ )
    data->str[i] = readChar( _file );

  data->str[s] = '\0';

  return data;
}

char *getNextNum( char *_str, char _end, unsigned long int *_num ) {
  if ( _str == NULL )
    return NULL;

  char buffer[25];

  for ( size_t i = 0; i < 25; i++ ) {
    buffer[i] = *_str;
    _str++;

    /* End of size num */
    if ( buffer[i] == _end ) {
      buffer[i] = '\0';
      break;
    }

    if ( buffer[i] < '0' || buffer[i] > '9' )
      return NULL;
  }

  *_num = strtoul( buffer, NULL, 10 );
  if ( *_num == ULONG_MAX )
    return NULL;

  return _str;
}
