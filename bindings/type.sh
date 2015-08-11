#!/bin/bash

BASHBinding::genCastFromChar() {
  argsRequired 4 $#
  local i

  if (( ${#3} > 0 )); then
    if [[ "$2" == 'char' ]]; then
      echo -e "$4;"
    else
      echo -e "($2 $3)$4;"
    fi
  else
    for i in $2; do
      case "$i" in
        char)   echo "($2)*$4;";                     return 0 ;;
        int)    echo "($2)strtol( $4, NULL, 10 );";  return 0 ;;
        float)  echo "($2)strtof( $4, NULL, 10 );";  return 0 ;;
        double) echo "($2)strtold( $4, NULL, 10 );"; return 0 ;;
      esac
    done
  fi
}

BASHBinding::genCast2Char() {
  argsRequired 6 $#
  local t="$2" ptr="$3" name="$4" size="$5" isPTR="$6"
  local snprintfType i
  echo "  // t: '$t'; ptr: '$ptr'; name: '$name'; size='$size'; isPTR: '$isPTR'"
  if [[ "$isPTR" == 'true' ]]; then
    echo '  ret->length = 0;'
    echo "  ret->data   = ( char * )$name;"
  else
    snprintfType="i"
    for i in $t; do
      if [[ "$i" == 'char' ]]; then
        # Chars and strings are easy
        if [ -z "$size" ]; then
          # single char
          echo "  ret->length = sizeof( char );"
          echo '  ret->data   = malloc( ret->length );'
          echo "  *ret->data  = ${ptr}${name}"
          return
        else
          # string
          echo "  ret->length = sizeof( char ) * $size;"
          echo '  ret->data   = malloc( ret->length );'
          echo "  strcpy( ret->data, ${ptr/#\*}${name} );"
          return
        fi
      fi
      case "$i" in
        unsigned) snprintfType="${snprintfType/%i}u" ;;
        long)     snprintfType="l${snprintfType}"    ;;
        short)    snprintfType="h${snprintfType}"    ;;
        double)   snprintfType="${snprintfType/%i}f" ;;
        float)    snprintfType="${snprintfType/%i}f" ;;
        int) [[ "$snprintfType" != *"u" ]] && snprintfType="${snprintfType/%i}i" ;;
      esac
    done

    if [ -z "$size" ]; then
      echo "  ret->length = sizeof( char ) * snprintf( NULL, 0, \"%$snprintfType\", ${ptr}${name} ) + 1;"
      echo '  ret->data   = malloc( ret->length );'
      echo "  snprintf( ret->data, ret->length, \"%$snprintfType\", ${ptr}${name} );"
    else
      echo '  ret->length = 0;'
      echo "  $t ${ptr}${name}_start = $name;"
      echo ''
      echo '  /* Calculate total size */'
      echo "  for( int ${name}_i = 0; ${name}_i < $size; ${name}_i++ ) {"
      echo "    ret->length += snprintf( NULL, 0, \"%$snprintfType \", ${ptr}${name} );"
      echo "    $name += sizeof( $t );"
      echo '  }'
      echo '  ret->length += 1; /* \0 at the end */'
      echo '  ret->data   = malloc( ret->length );'
      echo ''
      echo "  char *${name}_worker = ret->data;"
      echo "  $name = ${name}_start;"
      echo "  for( int ${name}_i = 0; ${name}_i < $size; ${name}_i++ ) {"
      echo "    ${name}_worker += snprintf( ${name}_worker, ret->length - ( ${name}_worker - ret->data ), \"%$snprintfType \", ${ptr}${name} );"
      echo "    $name += sizeof( $t );"
      echo '  }'
    fi
  fi
}

BASHBinding::resolveTypedef() {
  argsRequired 5 $#
  programRequired 'g++'
  local i name t typeOnly inclDirs
  name="$(readlink -f "$4")/tmp.cpp"
  t="${2/%*( )}"
  typeOnly="${t//\*}"
  typeOnly="${typeOnly//const}"
  typeOnly="${typeOnly//?(un)signed}"

  [ -f "$name" ] && rm "$name"

  for i in $3; do
    echo "#include <$i>" >> "$name"
  done

  cat << EOF >> "$name"

#include <iostream>
#include <type_traits>
#include <string>

template <bool B, typename T, int N>
struct worker {
  typedef T type;
  static const int counter = 1000;
};

template <typename T, int N>
struct worker<false, T, N> {
  typedef T type;
  static const int counter = N;
};

template <typename T, int N>
struct worker<true, T, N> : worker<std::is_pointer<typename std::remove_pointer<T>::type>::value,
                                   typename std::remove_pointer<T>::type,
                                   N + 1> {};

template <typename T>
struct count_ptr : worker<std::is_pointer<T>::value, T, 0> {};


void append( std::string &s, std::string a ) {
  if ( s.empty() ) {
    s += a;
  } else {
    s += " ";
    s += a;
  }
}

const size_t CHAR    = sizeof( char );
const size_t SINT    = sizeof( short int );
const size_t INT     = sizeof( int );
const size_t LINT    = sizeof( long int );
const size_t LLINT   = sizeof( long long int );
const size_t FLOAT   = sizeof( float );
const size_t DOUBLE  = sizeof( double );
const size_t LDOUBLE = sizeof( long double );


int main() {
  std::string str;

  int pointerLevel = count_ptr<$t>::counter;
  typedef count_ptr<$t>::type type;

  size_t size = sizeof( type );

  if ( std::is_const<type>::value )
    append( str, "const" );

  if ( std::is_signed<type>::value )
    append( str, "signed" );

  if ( std::is_unsigned<type>::value )
    append( str, "unsigned" );

  if ( std::is_fundamental<type>::value ) {
    if ( std::is_integral<type>::value ) {
      switch( size ) {
        case CHAR:    append( str, "char" );          break;
        case SINT:    append( str, "short int" );     break;
        case INT:     append( str, "int" );           break;
        case LINT:    append( str, "long int" );      break;
      }

      if ( LINT != LLINT )
        if ( size == LLINT )
          append( str, "long long int" );

    } else if ( std::is_floating_point<type>::value ) {
      switch( size ) {
        case FLOAT:   append( str, "float" );         break;
        case DOUBLE:  append( str, "double" );        break;
        case LDOUBLE: append( str, "long double" );   break;
      }
    }
  } else {
    // struct
    if ( std::is_pointer<$typeOnly>::value ) {
      std::cout << "$t" << std::endl;
      return 1;
    }
    append( str, "$typeOnly" );
  }

  if ( std::is_void<type>::value )
    append( str, "void" );



  std::cout << str << " ";
  for ( int i = 0; i < pointerLevel; i++ )
    std::cout << '*';
  std::cout << std::endl;

  return 0;
}

EOF

  for i in $5; do
    inclDirs="$inclDirs -I$i"
  done

  g++ -o "${name/%.cpp}" "$name" -Wall -std=c++11 -O0 $inclDirs
  (( $? != 0 )) && die "Failed to resolve type"

  ${name/%.cpp}

  for i in "${name/%.cpp}" "$name"; do
    [ -e "$i" ] && rm "$i"
  done
}
