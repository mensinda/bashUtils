#include "tidVector.h"
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

struct tidVector {
  size_t size;
  size_t capacity;

  pthread_t *data;
};

struct tidVector *tid_init() {
  struct tidVector *v = malloc( sizeof( struct tidVector ) );

  v->size = 0;
  v->capacity = VEC_START_SIZE;

  v->data = malloc( sizeof( pthread_t ) * v->capacity );

  return v;
}

int tid_expandIfNeeded( struct tidVector *_v ) {
  if ( _v == NULL )
    return -1;

  if ( _v->data == NULL )
    return -2;

  /* remove the finished threads */
  if ( _v->size == _v->capacity ) {
    for ( size_t i = 0; i < _v->size; i++ ) {
      if ( pthread_kill( _v->data[i], 0 ) != 0 ) {

        for ( size_t j = i; j < ( _v->size - 1 ); j++ )
          _v->data[j] = _v->data[j + 1];

        i--;
        _v->size--;
      }
    }
  }

  /* no threads finished --> increase capacity */
  if ( _v->size == _v->capacity ) {
    _v->capacity += VEC_EXPAND_SIZE;
    _v->data = realloc( _v->data, sizeof( pthread_t ) * _v->capacity );

    if ( _v->data == NULL )
      return -4;
  }

  return 0;
}

int tid_create( struct tidVector *_v, void *( *_f )( void * ), void *_data ) {
  int retExpand = tid_expandIfNeeded( _v ); /* _v pointer checking happens here */
  if ( retExpand != 0 )
    return retExpand;

  int ret = pthread_create( &_v->data[_v->size], NULL, _f, _data );
  if ( ret != 0 )
    return ret;

  _v->size++;

  return 0;
}

int tid_joinAll( struct tidVector *_v ) {
  if ( _v == NULL )
    return -1;

  if ( _v->data == NULL )
    return -2;

  for ( size_t i = 0; i < _v->size; i++ )
    pthread_join( _v->data[i], NULL );

  _v->size = 0;

  return 0;
}

void tid_free( struct tidVector *_v ) {
  if ( _v == NULL )
    return;

  tid_joinAll( _v );

  if ( _v->data != NULL )
    free( _v->data );

  free( _v );
}
