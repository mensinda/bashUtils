#!/bin/bash

BASHBinding::bbind_generateFiles() {
  argsRequired 2 $#
  fileRequired "$2" require

  local dir hFile cFile tFile cmakeFile mainFile line lineCounter=0
  local strINCLUDE strCMAKE
  local inludeList
  local includeDirs=() subDirs=()
  local returnType funcName argList argList2 i I I_OLD tmp opts
  local inCounter=0 outCounter=0
  declare -a argv
  declare -A argProps

  dir="$(readlink -f "$(dirname "$2")")"
  hFile="$dir/bind.h"
  cFile="$dir/bind.c"
  tFile="$dir/bindInit.c"
  cmakeFile="$dir/CMakeLists.txt"
  mainFile="$dir/main.c"

  inludeList="stdio.h binding.h"
  includeDirs+=("$(readlink -f "$(dirname "${BASH_SOURCE[0]}")/src")")
  subDirs+=("BASHbinding")


###    ______              _                __ _ _                                  __ _
###    | ___ \            (_)              / _(_) |                                / _(_)
###    | |_/ /_ _ _ __ ___ _ _ __   __ _  | |_ _| | ___   ______    ___ ___  _ __ | |_ _  __ _
###    |  __/ _` | '__/ __| | '_ \ / _` | |  _| | |/ _ \ |______|  / __/ _ \| '_ \|  _| |/ _` |
###    | | | (_| | |  \__ \ | | | | (_| | | | | | |  __/          | (_| (_) | | | | | | | (_| |
###    \_|  \__,_|_|  |___/_|_| |_|\__, | |_| |_|_|\___|           \___\___/|_| |_|_| |_|\__, |
###                                 __/ |                                                 __/ |
###                                |___/                                                 |___/

  while read line; do
    (( lineCounter++ ))
    line="${line/\#*/}"
    line="${line/%*( )/}"
    line="${line/#*( )/}"
    [ -z "$line" ] && continue

    case "${line/%:*/}" in
      include)
        inludeList="$inludeList ${line/#include:*( )/}";
        strINCLUDE="$strINCLUDE\n#include <${line/#include:*( )/}>"
        msg3 "Adding include for '${line/#include:*( )/}'"
        ;;
      includeDir)
        i="$(readlink -f "$dir/${line/#*:*( )}")"
        includeDirs+=("$i")
        strCMAKE="$strCMAKE\ninclude_directories( $i )\n"
        msg3 "Adding include directory '$i' to the compiler options"
        ;;
      subDir)
        i="$(readlink -f "$dir/${line/#*]*( )}")"
        I="${line/%*( )]*}"
        I="${I/#*[*( )}"
        includeDirs+=("$i")
        subDirs+=( "$I" )
        strCMAKE="$strCMAKE\nadd_subdirectory( $i \${PROJECT_BINARY_DIR}/$I )"
        strCMAKE="$strCMAKE\ninclude_directories( $i )\n"
        msg3 "Added subdir target '$I'"
        ;;
      beginBinding) break ;;
    esac
  done < "$2"

###     _____              _____ ___  ___      _        _     _     _        _        _
###    |  __ \            /  __ \|  \/  |     | |      | |   (_)   | |      | |      | |
###    | |  \/ ___ _ __   | /  \/| .  . | __ _| | _____| |    _ ___| |_ ___ | |___  _| |_
###    | | __ / _ \ '_ \  | |    | |\/| |/ _` | |/ / _ \ |   | / __| __/ __|| __\ \/ / __|
###    | |_\ \  __/ | | | | \__/\| |  | | (_| |   <  __/ |___| \__ \ |_\__ \| |_ >  <| |_
###     \____/\___|_| |_|  \____/\_|  |_/\__,_|_|\_\___\_____/_|___/\__|___(_)__/_/\_\\__|
###

cat << EOF > "$cmakeFile"
#
# WARNING: This is an automatically generated file!
#

cmake_minimum_required(VERSION 2.8.8)

project( $(basename "$dir") )
set( CMAKE_C_STANDARD 11 )

add_executable( binding main.c bind.c bindInit.c )

add_subdirectory( ${includeDirs[0]} \${PROJECT_BINARY_DIR}/${subDirs[0]} )
include_directories( ${includeDirs[0]} )

EOF

echo -e "$strCMAKE" >> "$cmakeFile"
echo "target_link_libraries( binding ${subDirs[*]} )" >> "$cmakeFile"


cat << EOF > "$mainFile"
/*
 * WARNING: This is an automatically generated file!
 */

#include <stdio.h>
#include <stdlib.h>
#include "bind.h"

int main( int argc, char const *argv[] ) {
  if ( argc != 2 ) {
    printf( "binding: ERROR: binding needs exactly one parameter (currently %i)\n", argc );
    return 1;
  }

  struct bindingINFO *inf = bbind_newINFO();
  bbind_initBindings( inf );

  if ( bbind_init( inf, argv[1] ) != 0 ) {
    printf( "binding: ERROR: failed to init\n" );
    return 2;
  }

  return bbind_run( inf );
}
EOF

###     _____              _     _           _ _                __ _ _
###    |  __ \            | |   (_)         | (_)              / _(_) |
###    | |  \/ ___ _ __   | |__  _ _ __   __| |_ _ __   __ _  | |_ _| | ___  ___
###    | | __ / _ \ '_ \  | '_ \| | '_ \ / _` | | '_ \ / _` | |  _| | |/ _ \/ __|
###    | |_\ \  __/ | | | | |_) | | | | | (_| | | | | | (_| | | | | | |  __/\__ \
###     \____/\___|_| |_| |_.__/|_|_| |_|\__,_|_|_| |_|\__, | |_| |_|_|\___||___/
###                                                     __/ |
###                                                    |___/

cat << EOF > "$hFile"
/*
 * WARNING: This is an automatically generated file!
 */
#ifndef BASH_BIND_H
#define BASH_BIND_H

#include <stdio.h>
#include <binding.h>
EOF

echo -e "$strINCLUDE" >> "$hFile"

cat << EOF > "$cFile"
/*
 * WARNING: This is an automatically generated file!
 */
#include "bind.h"
#include <string.h>
#include <stdlib.h>
EOF

cat << EOF > "$tFile"
/*
 * WARNING: This is an automatically generated file!
 */
#include "bind.h"

void bbind_initBindings( struct bindingINFO *_inf ) {
EOF

###    ______              _                __ _ _                 _     _           _ _
###    | ___ \            (_)              / _(_) |               | |   (_)         | (_)
###    | |_/ /_ _ _ __ ___ _ _ __   __ _  | |_ _| | ___   ______  | |__  _ _ __   __| |_ _ __   __ _ ___
###    |  __/ _` | '__/ __| | '_ \ / _` | |  _| | |/ _ \ |______| | '_ \| | '_ \ / _` | | '_ \ / _` / __|
###    | | | (_| | |  \__ \ | | | | (_| | | | | | |  __/          | |_) | | | | | (_| | | | | | (_| \__ \
###    \_|  \__,_|_|  |___/_|_| |_|\__, | |_| |_|_|\___|          |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/
###                                 __/ |                                                       __/ |
###                                |___/                                                       |___/

  while read line; do
    (( lineCounter-- ))
    (( lineCounter >= 0 )) && continue;
    line="${line/\#*/}"
    line="${line/%*( )/}"
    line="${line/#*( )/}"
    [ -z "$line" ] && continue

    argList2=''
    funcName="${line/%*( )(*/}"
    returnType="${line/#*-->*( )/}"
    argList="${line/#*[(]*( )/}"
    argList="${argList/%*( ))*/}"
    OIFS=$IFS
    IFS=,
    argv=( $argList )
    IFS=$OIFS

    found2 "Function '$funcName'" 1>&2

    [[ "$returnType" != 'void' ]] && \
      returnType="$($1 . bbind_resolveTypedef "$returnType" "$inludeList" "$dir" "${includeDirs[*]}")"
    tmp="${returnType//[^*]/}"

    returnType="${returnType//const}" # removing consts
    returnType="${returnType/#*( )}"
    returnType="${returnType/%*( )}"
    returnType="${returnType//+( )/ }"
    returnType="$returnType $tmp"     # fixing pointers

    argProps["0:type"]="$returnType"
    argProps["0:pointer"]="$tmp"
    [[ "$returnType" != 'void ' ]] && argProps["0:opts"]="out"

    echo -ne "\nint bbind_funcBind_$funcName( struct bindingCALL *_arg, struct bindingCALL *_ret );"  1>&6
    echo -e  "\nint bbind_funcBind_$funcName( struct bindingCALL *_arg, struct bindingCALL *_ret ) {"
    echo -n  "  bbind_addFunction( _inf, &bbind_funcBind_$funcName, \"$funcName\", "                  1>&3

    for (( i = 0; i < ${#argv[@]}; )); do
      opts=''
      I="${argv[$i]}"
      (( i++ ))

      if [[ "$I" != "${I//|}" ]]; then
        opts="${I/#*([^|])|*( )}"
        opts="${opts/%*( )\|*([^|])}"
      fi
      I="${I//|*|}"   # removing opts
      I_OLD="$I"

      [[ "$I" != 'void' ]] && I="$($1 . bbind_resolveTypedef "$I" "$inludeList" "$dir" "${includeDirs[*]}")"
      tmp="${I//[^*]/}"

      I="${I//const}" # removing consts
      I="${I//\*}"    # removing pointers
      I="${I/#*( )}"
      I="${I/%*( )}"
      I="${I//+( )/ }"

      [ -z "$opts" ] && opts='in'
      [[ "$opts" == *"DUMMY"* && "$opts" != *"in"* && "$opts" != *"out"* ]] && opts="$opts in"

      echo "  /* parameter $i; mata: '$opts' */"

      if [[ "$opts" == *"in"* ]]; then
        (( inCounter++ ))
        echo '  if ( _arg == NULL ) {'
        echo '    printf( "binding: ERROR: func: $funcName _arg is NULL" );'
        echo '    return 1;'
        echo '  }'
        echo -n "  $I ${tmp}arg$i = "
        $1 . bbind_genCastFromChar "$I" "$tmp" "_arg->data"
        echo '  _arg = _arg->next;'
        echo ''

        [[ "$opts" != *"DUMMY"* ]] && argList2="$argList2 arg${i},"
      elif [[ "$opts" == *"out"* ]]; then
        if [[ "$opts" == *"!"* ]]; then
          tmp="${tmp/#\*}"
          echo "  $I ${tmp}arg$i;"
          echo ''
          argList2="$argList2 ($I_OLD)&arg${i}/* Explicit cast to silent warnings */,"
        else
          echo "  $I ${tmp}arg$i;"
          echo ''
          argList2="$argList2 arg${i},"
        fi
      fi

      argProps["$i:type"]="$I"
      argProps["$i:pointer"]="$tmp"
      argProps["$i:opts"]="${opts}"
    done

    for (( i = 0; i <= ${#argv[@]}; i++ )); do
      if [[ "${argProps[$i:opts]}" == *":"* ]]; then
        if [[ "${argProps[$i:opts]}" != *"in"* ]]; then
          I="${argProps[$i:opts]}"
          I="${I/#*:}"
          I="${I/%*( )}"
          [[ ! "${argProps[$I:opts]}" == *"in"* ]] && \
            echo "#error \"'arg$I' has not the attribute 'in' ('${argProps[$I:opts]}')\""
          echo "  arg$i = malloc( sizeof( ${argProps[$i:type]} ) * (${argProps[$I:pointer]}arg$I) );"
        fi
      fi
    done

    echo ''

    argList2="${argList2/%,}"
    if [[ "$returnType" != 'void ' ]]; then
      echo "  ${returnType}arg0 = $funcName($argList2 );"
    else
      echo "  $funcName($argList2 );"
    fi

    echo ''
    echo '  struct bindingCALL *ret = _ret;'
    echo ''

    for (( i = 0; i <= ${#argv[@]}; i++ )); do
      [[ "${argProps[$i:opts]}" != *"out"* ]] && continue
      [[ "${argProps[$i:type]}" == 'void ' ]] && continue
      (( outCounter++ ))
      I="${argProps[$i:opts]}"
      I="${I/%*( )}"
      if   [[ "$I" == *":"* ]]; then
        I="${I/#*:}"
        I="arg$I"
      elif [[ "$I" == *"!"* ]]; then
        I="${I/#*!}"
        I="arg$I"
      else
        I=''
      fi

      if (( "${#argProps[$i:pointer]}" > 0 && "${#I}" == 0 )); then
        echo ''
        echo '  ret = bbind_newCALL();'
        $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" '' 'true'
        echo '  ret = ret->next;'
      fi

      echo ''
      echo '  ret = bbind_newCALL();'
      $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" "$I" 'false'
      echo '  ret = ret->next;'
    done

    echo ''

    for (( i = 0; i <= ${#argv[@]}; i++ )); do
      if [[ "${argProps[$i:opts]}" == *":"* ]]; then
        if [[ "${argProps[$i:opts]}" != *"in"* ]]; then
          echo "  free( arg$i );"
        fi
      fi
    done

    echo "$inCounter, $outCounter );" 1>&3
    echo -e "\n  return 0;\n}"

    inCounter=0
    outCounter=0

  done < "$2" 1>> "$cFile" 3>> "$tFile" 6>> "$hFile"

  echo -e "\n\nvoid bbind_initBindings( struct bindingINFO *_inf );" >> "$hFile"
  echo -e "\n#endif /* BIND_H */"                                    >> "$hFile"
  echo "}"                                                           >> "$tFile"
}
