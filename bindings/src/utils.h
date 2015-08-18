#ifndef BBINDING_UTILS_H
#define BBINDING_UTILS_H

#include "stdio.h"

struct stringAndInfPtr {
  struct bindingINFO *inf;
  char *str;
};

struct stringAndInfPtr *new_stringAndInfPtr();
void free_stringAndInfPtr( struct stringAndInfPtr *_s );

/*
 * Reads a char from _file and exists if EOF
 */
int readChar( FILE *_file );

struct stringAndInfPtr *readSizedInput( FILE *_file, struct bindingINFO *_inf );

char *getNextNum( char *_str, char _end, unsigned long int *_num );

#endif /* end of include guard: BBINDING_UTILS_H */
