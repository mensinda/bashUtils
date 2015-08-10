#ifndef BASH_BINDING_H
#define BASH_BINDING_H

#include <stdio.h>

extern const char *FIFO_NAMES[];
extern const unsigned int MAX_FIFO_NAME_LEN;

struct bindingINFO;
struct bindingCALL {
  size_t length;
  char *data;

  struct bindingCALL *next;
};

typedef int ( *bindingFunctionPTR )( struct bindingCALL *, struct bindingCALL * );


struct bindingINFO *bbind_newINFO();
struct bindingCALL *bbind_newCALL();

int bbind_addFunction( struct bindingINFO *_inf,
                       bindingFunctionPTR ptr,
                       char const *_name,
                       char const *_params );

int bbind_init( struct bindingINFO *_inf, char const *_dir );
int bbind_end( struct bindingINFO *_inf );

#endif /* end of include guard: BASH_BINDING_H */
