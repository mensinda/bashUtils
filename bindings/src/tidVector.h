#ifndef BINDING_TID_VECTOR_H
#define BINDING_TID_VECTOR_H

#include <pthread.h>

#ifndef VEC_START_SIZE
#define VEC_START_SIZE 10
#endif

#ifndef VEC_EXPAND_SIZE
#define VEC_EXPAND_SIZE 5
#endif

struct tidVector;

struct tidVector *tid_init();

int tid_create( struct tidVector *_v, void *( *_f )( void * ), void *_data );
int tid_joinAll( struct tidVector *_v );

void tid_free( struct tidVector *_v );


#endif /* end of include guard: BINDING_TID_VECTOR_H */
