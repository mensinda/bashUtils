#!/bin/bash

BASHBinding::bbind_generateFiles() {
  argsRequired 2 $#
  fileRequired "$2" require

  local dir hFile cFile tFile cmakeFile mainFile line lineCounter=0 lineCounterOld OIFS
  local strINCLUDE strLINK strCMAKE
  local inludeList
  local includeDirs=() subDirs=()
  local returnType funcName argList argList2 i I j I_OLD tmp opts isStruct
  local inCounter=0 outCounter=0
  declare -a argv
  declare -A argProps
  declare -A typeIndex

  dir="$(readlink -f "$(dirname "$2")")"

  [ ! -d "$dir/src" ] && mkdir "$dir/src"

  hFile="$dir/src/bind.h"
  cFile="$dir/src/bind.c"
  tFile="$dir/src/bindInit.c"
  cmakeFile="$dir/CMakeLists.txt"
  mainFile="$dir/src/main.c"

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
      link)
        strLINK="$strLINK ${line/#link:*( )/}"
        msg3 "Linking against '${line/#link:*( )/}'"
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
      beginCallback) break ;;
      beginBinding)
        (( lineCounter-- ))
        break ;;
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

add_executable( binding $cFile $tFile $mainFile )

add_subdirectory( ${includeDirs[0]} \${PROJECT_BINARY_DIR}/${subDirs[0]} )
include_directories( ${includeDirs[0]} )

EOF

echo -e "$strCMAKE" >> "$cmakeFile"
echo "target_link_libraries( binding ${subDirs[*]} $strLINK )" >> "$cmakeFile"


cat << EOF > "$mainFile"
/*
 * WARNING: This is an automatically generated file!
 */

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
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

  bbind_run( inf );
  pthread_exit( NULL );
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

###    ______              _                __ _ _                           _ _ _                _
###    | ___ \            (_)              / _(_) |                         | | | |              | |
###    | |_/ /_ _ _ __ ___ _ _ __   __ _  | |_ _| | ___   ______    ___ __ _| | | |__   __ _  ___| | _____
###    |  __/ _` | '__/ __| | '_ \ / _` | |  _| | |/ _ \ |______|  / __/ _` | | | '_ \ / _` |/ __| |/ / __|
###    | | | (_| | |  \__ \ | | | | (_| | | | | | |  __/          | (_| (_| | | | |_) | (_| | (__|   <\__ \
###    \_|  \__,_|_|  |___/_|_| |_|\__, | |_| |_|_|\___|           \___\__,_|_|_|_.__/ \__,_|\___|_|\_\___/
###                                 __/ |
###                                |___/

  msg3 "Prsing callback declarations"

  lineCounterOld=$lineCounter
  while read line; do
    (( lineCounterOld-- ))
    (( lineCounterOld >= 0 )) && continue;
    (( lineCounter++ ))

    line="${line/\#*}"
    line="${line/%*( )}"
    line="${line/#*( )}"
    [ -z "$line" ] && continue
    [[ "$line" == "beginBinding:" ]] && break

    returnType="${line/%*( )(*}"
    funcName="${line/%*( ))*}"
    funcName="${funcName/#*\**( )}"
    argList="${line/#*\(*( )}"
    argList="${argList/%*( ))*}"
    OIFS=$IFS
    IFS=,
    argv=( $argList )
    IFS=$OIFS

    found3 "Callback '$funcName'" 1>&2

    isStruct=0
    if [[ "$returnType" != 'void' ]]; then
      if [[ "${typeIndex[${returnType}::t]}" == "" ]]; then
        typeIndex[${returnType}::t]="$($1 . bbind_resolveTypedef "$returnType" "$inludeList" "$dir" "${includeDirs[*]}")"
        isStruct=$?
        typeIndex[${returnType}::s]="$isStruct"
        returnType="${typeIndex[${returnType}::t]}"
      else
        isStruct="${typeIndex[${returnType}::s]}"
        returnType="${typeIndex[${returnType}::t]}"
      fi
    fi
    tmp="${returnType//[^*]/}"

    returnType="${returnType//const}" # removing consts
    returnType="${returnType/#*( )}"
    returnType="${returnType/%*( )}"
    returnType="${returnType//+( )/ }"
    returnType="$returnType $tmp"     # fixing pointers

    echo -ne  "\n${returnType}bbind_funcCB_$funcName( struct bindingINFO *_inf, const char *_id"

    local oldIsStruct="$isStruct"
    for (( i = 0; i < ${#argv[@]}; i++ )); do
      I="${argv[$i]}"
      opts=''

      if [[ "$I" != "${I//|}" ]]; then
        opts="${I/#*([^|])|*( )}"
        opts="${opts/%*( )\|*([^|])}"
      fi

      I="${I//|*|}"   # removing opts
      I_OLD="$I"

      isStruct=0
      if [[ "$I" != 'void' && "$opts" != *"FPTR"* ]]; then
        if [[ "${typeIndex[${I}::t]}" == "" ]]; then
          typeIndex[${I}::t]="$($1 . bbind_resolveTypedef "$I" "$inludeList" "$dir" "${includeDirs[*]}")"
          isStruct=$?
          typeIndex[${I}::s]="$isStruct"
          I="${typeIndex[${I}::t]}"
        else
          isStruct="${typeIndex[${I}::s]}"
          I="${typeIndex[${I}::t]}"
        fi
      fi
      tmp="${I//[^*]/}"

      I="${I//\*}"    # removing pointers
      I="${I/#*( )}"
      I="${I/%*( )}"
      I="${I//+( )/ }"

      echo -n ", $I ${tmp}arg$i"

      argProps["$i:type"]="$I"
      argProps["$i:pointer"]="$tmp"
      argProps["$i:opts"]="${opts}"
      argProps["$i:isStruct"]="$isStruct"
    done
    isStruct="$oldIsStruct"

    echo " ) {"

    echo ''
    echo '  struct bindingCALL  *ret  = NULL;'
    echo '  struct bindingCALL  *out  = NULL;'
    echo '  struct bindingCALL **retP = &ret;'
    echo ''

    j=0
    for (( i = 0; i < ${#argv[@]}; i++ )); do
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
        echo '  *retP = bbind_newCALL();'
        echo '  ret = *retP;'
        (( j == 0 )) && echo '  out = ret;'
        $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" '' 'true' "${argProps[$i:isStruct]}"
        echo "  ret->isPTR = '1';"
        echo '  retP = &ret->next;'
        j=1
      fi

      [[ "${argProps[$i:isStruct]}" ==  '1'     ]] && continue # struct
      [[ "${argProps[$i:type]}"     == *'void'* ]] && continue

      echo ''
      echo '  *retP = bbind_newCALL();'
      echo '  ret = *retP;'
      (( j == 0 )) && echo '  out = ret;'
      $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" "$I" 'false' "${argProps[$i:isStruct]}"
      echo "  ret->isPTR = '0';"
      echo '  retP = &ret->next;'
      j=1
    done

    tmp="${returnType//[^*]/}"

    returnType="${returnType/#*( )}"
    returnType="${returnType/%*( )}"

    if [[ "$returnType" == 'void' && "$tmp" == '' ]]; then
      echo '  generateCALLBACK( _inf, _id, out );'
      echo '}'
      echo "#define BBIND_CALLBACK_HELPER_$funcName \"bbind_funcCB_$funcName\", \"$returnType\", \"$tmp\", \"$I\""
      continue
    fi

    echo ''
    echo '  struct bindingCALL *retVal = NULL;'
    echo '  retVal = generateCALLBACK( _inf, _id, out );'
    echo ''
    echo '  if ( retVal == NULL ) {'
    echo "    printf( \"binding: ERROR: func: $funcName retVal is NULL\n\" );"
    echo "    $returnType ${tmp}ret;"
    echo "    return ret;"
    echo '  }'
    echo ''

    # 'char *' is special
    j=0
    if [[ "${#tmp}" == '1' ]]; then
      for j in $returnType; do
        if [[ "$j" == 'char' ]]; then
          echo "  $returnType ${tmp}retType = ($returnType ${tmp})retVal->data;"
          j=-1
          break
        fi
      done
    fi

    # No strings (int, etc)
    if (( ${#tmp} > 0 && j == 0 )); then
      echo "  $returnType ${tmp}ret;"
      echo "  if ( retVal->isPTR == '1' ) {"
      echo -n "    retType = "
      $1 . bbind_genCastFromChar "$returnType" "$tmp" "retVal->data" "$isStruct"
      echo -n '  }'
      if [[ "$opts" == *"!"* || "$opts" == *":"* ]]; then
        echo ''
      else
        echo ' else {'
        if (( isStruct == 0 )); then
          echo -n "    ${tmp}retType = "
          $1 . bbind_genCastFromChar "$returnType" "" "retVal->data" "$isStruct"
        else
          echo "    printf( \"binding: ERROR: struct inputs MUST be pointers!\" );"
          echo "    return 2;"
        fi
        echo '  }'
      fi
      echo ''
    elif (( j == 0 )); then
      echo -n "  $returnType ${tmp}retType = "
      $1 . bbind_genCastFromChar "$returnType" "$tmp" "retVal->data" "$isStruct"
    fi

    echo ''
    echo '  bbind_freeCALL( retVal );'
    echo '  return retType;'

    echo "}"
    echo ''
    for (( i = 0; i < ${#argv[@]}; i++ )); do
      if (( i == 0 )); then
        tmp="${argProps[$i:type]} _$i"
        I="_$i"
      else
        tmp="${tmp}, ${argProps[$i:type]} _$i"
        I="$I, _$i"
      fi
    done
    echo "#define BBIND_CALLBACK_HELPER_$funcName \"bbind_funcCB_$funcName\", \"$returnType\", \"$tmp\", \"$I\""

  done < "$2" 1>> "$cFile" 3>> "$tFile"

###    ______              _                __ _ _                 _     _           _ _
###    | ___ \            (_)              / _(_) |               | |   (_)         | (_)
###    | |_/ /_ _ _ __ ___ _ _ __   __ _  | |_ _| | ___   ______  | |__  _ _ __   __| |_ _ __   __ _ ___
###    |  __/ _` | '__/ __| | '_ \ / _` | |  _| | |/ _ \ |______| | '_ \| | '_ \ / _` | | '_ \ / _` / __|
###    | | | (_| | |  \__ \ | | | | (_| | | | | | |  __/          | |_) | | | | | (_| | | | | | (_| \__ \
###    \_|  \__,_|_|  |___/_|_| |_|\__, | |_| |_|_|\___|          |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/
###                                 __/ |                                                       __/ |
###                                |___/                                                       |___/

  msg3 "Prsing function declarations"

  while read line; do
    (( lineCounter-- ))
    (( lineCounter >= 0 )) && continue;
    line="${line/\#*}"
    line="${line/%*( )}"
    line="${line/#*( )}"
    [ -z "$line" ] && continue

    argList2=''
    funcName="${line/%*( )(*}"
    returnType="${funcName/%*( )+([^ *])}"
    funcName="${funcName/#* *(\*)}"
    argList="${line/#*[(]*( )}"
    argList="${argList/%*( ))*}"
    OIFS=$IFS
    IFS=,
    argv=( $argList )
    IFS=$OIFS

    found3 "Function '$funcName'" 1>&2

    isStruct=0
    if [[ "$returnType" != 'void' ]]; then
      if [[ "${typeIndex[${returnType}::t]}" == "" ]]; then
        typeIndex[${returnType}::t]="$($1 . bbind_resolveTypedef "$returnType" "$inludeList" "$dir" "${includeDirs[*]}")"
        isStruct=$?
        typeIndex[${returnType}::s]="$isStruct"
        returnType="${typeIndex[${returnType}::t]}"
      else
        isStruct="${typeIndex[${returnType}::s]}"
        returnType="${typeIndex[${returnType}::t]}"
      fi
    fi
    tmp="${returnType//[^*]/}"

    returnType="${returnType//const}" # removing consts
    returnType="${returnType//\*}"    # removing pointers
    returnType="${returnType/#*( )}"
    returnType="${returnType/%*( )}"
    returnType="${returnType//+( )/ }"
    returnType="$returnType $tmp"     # fixing pointers

    argProps["0:type"]="$returnType"
    argProps["0:pointer"]="$tmp"
    argProps["0:isStruct"]="$isStruct"
    [[ "$returnType" != 'void ' ]] && argProps["0:opts"]="out"

    echo -ne "\nint bbind_funcBind_$funcName( struct bindingINFO *_inf, struct bindingCALL *_arg, struct bindingCALL **_ret );"  1>&6
    echo -e  "\nint bbind_funcBind_$funcName( struct bindingINFO *_inf, struct bindingCALL *_arg, struct bindingCALL **_ret ) {"
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

      isStruct=0
      if [[ "$I" != 'void' && "$opts" != *"FPTR"* ]]; then
        if [[ "${typeIndex[${I}::t]}" == "" ]]; then
          typeIndex[${I}::t]="$($1 . bbind_resolveTypedef "$I" "$inludeList" "$dir" "${includeDirs[*]}")"
          isStruct=$?
          typeIndex[${I}::s]="$isStruct"
          I="${typeIndex[${I}::t]}"
        else
          isStruct="${typeIndex[${I}::s]}"
          I="${typeIndex[${I}::t]}"
        fi
      fi
      tmp="${I//[^*]/}"

      I="${I//const}" # removing consts
      I="${I//\*}"    # removing pointers
      I="${I/#*( )}"
      I="${I/%*( )}"
      I="${I//+( )/ }"

      [ -z "$opts" ] && opts='in'
      [[ "$opts" == *"DUMMY"* && "$opts" != *"in"* && "$opts" != *"out"* ]] && opts="$opts in"

      echo ''
      echo "  /* parameter $i; type: '$I'; ptr: '$tmp'; mata: '$opts' */"
      echo "  struct bindingCALL *s_arg$i = _arg;"

      if [[ "$opts" == *"FPTR"* ]]; then
        echo '  if ( _arg == NULL ) {'
        echo "    printf( \"binding: ERROR: func: $funcName _arg is NULL\n\" );"
        echo '    return 1;'
        echo '  }'
        echo '  if ( _arg->data == NULL ) {'
        echo "    printf( \"binding: ERROR: func: $funcName _arg->data is NULL\n\" );"
        echo '    return 2;'
        echo '  }'
        echo ''
        (( inCounter++ ))
        echo "  $I ${tmp}arg$i = ($I ${tmp})bbind_genFunctionPointer( _inf, _arg->data, BBIND_CALLBACK_HELPER_$I );"
        [[ "$opts" != *"DUMMY"* ]] && argList2="$argList2 arg${i},"

      ##
      ## IN
      ##
      elif [[ "$opts" == *"in"* ]]; then
        echo '  if ( _arg == NULL ) {'
        echo "    printf( \"binding: ERROR: func: $funcName _arg is NULL\n\" );"
        echo '    return 1;'
        echo '  }'
        echo '  if ( _arg->data == NULL ) {'
        echo "    printf( \"binding: ERROR: func: $funcName _arg->data is NULL\n\" );"
        echo '    return 2;'
        echo '  }'
        echo ''
        (( inCounter++ ))
        j=0

        # 'char *' is special
        if [[ "$opts" != *"!"* && "$opts" != *":"* && "${#tmp}" == '1' ]]; then
          for j in $I; do
            if [[ "$j" == 'char' ]]; then
              echo "  $I ${tmp}arg$i = ($I ${tmp})_arg->data;"
              j=-1
              break
            fi
          done
        fi

        # No strings (int, etc)
        if (( ${#tmp} > 0 && j == 0 )); then
          if [[ ( "$isStruct" == '0' || "$isStruct" == '2' ) && "$I" != *'void'* ]]; then
            echo "  $I value_arg$i;"
            echo "  $I ${tmp}arg$i = ${tmp//\*/&}value_arg$i;"
          else
            echo "  $I ${tmp}arg$i = NULL;"
          fi
          echo "  if ( _arg->isPTR == '1' ) {"
          echo -n "    arg$i = "
          $1 . bbind_genCastFromChar "$I" "$tmp" "_arg->data" "$isStruct"
          echo -n '  }'
          if [[ "$opts" == *"!"* || "$opts" == *":"* ]]; then
            echo ''
          else
            echo ' else {'
            if [[ ( "$isStruct" == '0' || "$isStruct" == '2' ) && "$I" != *'void'* ]]; then
              echo -n "    ${tmp}arg$i = "
              $1 . bbind_genCastFromChar "$I" "" "_arg->data" "$isStruct"
            else
              echo "    printf( \"binding: ERROR: struct inputs MUST be pointers!\" );"
              echo "    return 2;"
            fi
            echo '  }'
          fi
          echo ''
        elif (( j == 0 )); then
          echo -n "  $I ${tmp}arg$i = "
          $1 . bbind_genCastFromChar "$I" "$tmp" "_arg->data" "$isStruct"
        fi
        echo '  _arg = _arg->next;'
        echo ''

        [[ "$opts" != *"DUMMY"* ]] && argList2="$argList2 arg${i},"

      ##
      ## OUT
      ##
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
      argProps["$i:isStruct"]="$isStruct"
    done




    for (( i = 0; i <= ${#argv[@]}; i++ )); do
      echo ''
      echo "  /* Setting arg$i */"
      if [[ "${argProps[$i:opts]}" != *":"* ]]; then
        echo '  /*  -- Nothing to do */'
        continue
      fi

      I="${argProps[$i:opts]}"
      I="${I/#*:}"
      I="${I/%*( )}"

      if [[ "${argProps[$i:opts]}" == *"in"* ]]; then
        echo "  if ( s_arg$i->isPTR == '0' ) {"
        [[ ! "${argProps[$I:opts]}" == *"in"* ]] && \
          echo "#error \"'arg$I' has not the attribute 'in' ('${argProps[$I:opts]}')\""
        echo "    /*  -- allocating memory based on arg$I */"
        echo "    arg$i = malloc( sizeof( ${argProps[$i:type]} ) * (${argProps[$I:pointer]}arg$I) );"

        # char (=string) is easy.
        for j in ${argProps[$i:type]}; do
          if [[ "$j" == 'char' ]]; then
            echo '    /*  -- Copying string */'
            echo "    strncpy( arg$i, s_arg${i}->data, sizeof( ${argProps[$i:type]} ) * (${argProps[$I:pointer]}arg$I) );"
            echo "  }"
            j='-1'
            break
          fi
        done
        [[ "$j" == '-1' ]] && continue

        echo "    /*  -- Filling non char array */"
        echo "    char   b_arg$i[25]; /* buffer */"
        echo "    size_t c_arg$i = 0; /* counter buffer */"
        echo "    size_t C_arg$i = 0; /* counter elemets */"
        echo "    char *worker$i = s_arg$i->data;"
        echo "    while ( *worker$i != '\0' ) {"
        echo "      if ( c_arg${i} >= 24 ) {"
        echo "        printf( \"binding: ERROR: internal buffer to small! (func: $funcName; arg$i)\n\" );"
        echo "        return 2;"
        echo '      }'
        echo ''
        echo "      if ( *worker$i == ' ' || *worker$i == '\n' || *worker$i == '\t' ) {"
        echo "        if ( c_arg$i == 0 ) continue;"
        echo "        if ( C_arg$i >= arg$I ) {"
        echo "          printf ( \"binding: ERROR: arg$i: 1: array size (%lu) does not match the number of elements (%lu).\n\", arg$I, C_arg$i );"
        echo "          return 3;"
        echo '        }'
        echo ''
        echo "        b_arg${i}[c_arg${i}] = '\0';"
        echo -n "        arg$i[C_arg$i] = "
        $1 . bbind_genCastFromChar "${argProps[$i:type]}" "" "b_arg${i}" "$isStruct"
        echo ''
        echo "        b_arg$i[c_arg${i}] = *worker$i;"
        echo "        c_arg$i = 0;"
        echo "        C_arg$i++;"
        echo '      } else {'
        echo "        b_arg${i}[c_arg${i}] = *worker$i;"
        echo "        c_arg${i}++;"
        echo '      }'
        echo "      worker$i++;"
        echo '    }'
        echo ''
        echo "    if ( c_arg$i != 0 ) {"
        echo "      if ( C_arg$i >= arg$I ) {"
        echo "        printf ( \"binding: ERROR: arg$i: 2: array size (%lu) does not match the number of elements (%lu).\n\", arg$I, C_arg$i );"
        echo "        return 3;"
        echo '      }'
        echo ''
        echo "      b_arg$i[c_arg$i] = '\0';"
        echo -n "      arg$i[C_arg$i] = "
        $1 . bbind_genCastFromChar "${argProps[$i:type]}" "" "b_arg${i}" "$isStruct"
        echo "      C_arg$i++;"
        echo '    }'
        echo "    if ( C_arg$i != arg$I ) {"
        echo "      printf ( \"binding: ERROR: arg$i: 3: array size (%lu) does not match the number of elements (%lu).\n\", arg$I, C_arg$i );"
        echo "      return 3;"
        echo '    }'
        echo '  }'
      else
        [[ ! "${argProps[$I:opts]}" == *"in"* ]] && \
          echo "#error \"'arg$I' has not the attribute 'in' ('${argProps[$I:opts]}')\""
        echo "  /*  -- allocating memory based on arg$I */"
        echo "  arg$i = malloc( sizeof( ${argProps[$i:type]} ) * (${argProps[$I:pointer]}arg$I) );"
      fi
    done

    echo ''
    echo "  /* Calling function '$funcName' */"

    argList2="${argList2/%,}"
    if [[ "$returnType" != 'void ' ]]; then
      echo "  ${returnType}arg0 = $funcName($argList2 );"
    else
      echo "  $funcName($argList2 );"
    fi

###    ______     _                      _
###    | ___ \   | |                    | |
###    | |_/ /___| |_ _   _ _ __ _ __   | |_ _   _ _ __   ___  ___
###    |    // _ \ __| | | | '__| '_ \  | __| | | | '_ \ / _ \/ __|
###    | |\ \  __/ |_| |_| | |  | | | | | |_| |_| | |_) |  __/\__ \
###    \_| \_\___|\__|\__,_|_|  |_| |_|  \__|\__, | .__/ \___||___/
###                                           __/ | |
###                                          |___/|_|

    echo ''
    echo '  struct bindingCALL **retP = _ret;'
    echo '  struct bindingCALL *ret   = NULL;'
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
        echo '  *retP = bbind_newCALL();'
        echo '  ret = *retP;'
        $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" '' 'true' "${argProps[$i:isStruct]}"
        echo "  ret->isPTR = '1';"
        echo '  retP = &ret->next;'
      fi

      [[ "${argProps[$i:isStruct]}" ==  '1'     ]] && continue
      [[ "${argProps[$i:type]}"     == *'void'* ]] && continue

      echo ''
      echo '  *retP = bbind_newCALL();'
      echo '  ret = *retP;'
      $1 . bbind_genCast2Char "${argProps[$i:type]}" "${argProps[$i:pointer]}" "arg$i" "$I" 'false' "${argProps[$i:isStruct]}"
      echo "  ret->isPTR = '0';"
      echo '  retP = &ret->next;'
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
