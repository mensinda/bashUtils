#ifndef BASH_BINDING_H
#define BASH_BINDING_H

#include <stdio.h>

struct bindingINFO;
struct bindingFUNC;
struct bindingCALL {
  size_t length;
  char *data;

  char isPTR;

  struct bindingCALL *next;
};

typedef int ( *bindingFunctionPTR )( struct bindingINFO *,
                                     struct bindingCALL *,
                                     struct bindingCALL ** );


struct bindingINFO *bbind_newINFO();
struct bindingFUNC *bbind_newFUNC();
struct bindingCALL *bbind_newCALL();

void bbind_freeINFO( struct bindingINFO *_s );
void bbind_freeFUNC( struct bindingFUNC *_s );
void bbind_freeCALL( struct bindingCALL *_s );

int bbind_addFunction( struct bindingINFO *_inf,
                       bindingFunctionPTR ptr,
                       char const *_name,
                       size_t _params,
                       size_t _return );

int bbind_addCallback( struct bindingINFO *_inf, char const *_name, void *_val );
void *bbind_genFunctionPointer( struct bindingINFO *_inf,
                                char const *_id,
                                char const *_fName,
                                char const *_return,
                                char const *_args,
                                char const *_argsNoType );

struct bindingCALL *generateCALLBACK( struct bindingINFO *_inf,
                                      char const *_id,
                                      struct bindingCALL *_args );

int bbind_init( struct bindingINFO *_inf, char const *_dir );
int bbind_run( struct bindingINFO *_inf );

#endif /* end of include guard: BASH_BINDING_H */
