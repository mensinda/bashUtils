#!/bin/bash

__CLASS_CURRENT_CLASS=""
__CLASS_CURRENT_ACCESS_RGHTS=""

class() {
  (( $# < 1 )) && die "class needs at least one parameter"
  local i j tmp
  for i in "$@"; do
    assertDoesNotContain "$1" ' '
  done

  declare -f "$func" &> /dev/null && die "Class '$1' already exists!"

  eval "$1() { __CLASS_createNewObject $1 \$*; }"
  declare -gA __CLASS_${1}_PROPERTIES
  declare -ga __CLASS_${1}_CONSTRUCTION_ORDER
  __CLASS_CURRENT_CLASS="$1"
  __CLASS_CURRENT_ACCESS_RGHTS='-'

  eval "__CLASS_${1}_CONSTRUCTION_ORDER=( '$1' )"

  for i in "${@:2}"; do
    declare -f "$i" &> /dev/null || die "Can not extend unkown class '$i'"
    eval "__CLASS_${1}_CONSTRUCTION_ORDER+=( \"\${__CLASS_${i}_CONSTRUCTION_ORDER[@]}\" )"
    eval "
      for j in \"\${!__CLASS_${i}_PROPERTIES[@]}\"; do
        tmp=\"\${__CLASS_${i}_PROPERTIES[\$j]}\"
        case \"\${tmp:0:1}\" in
          '+') __CLASS_updateClassDef \"\$j\" \"+\${tmp:1:1}$i\" ;;
          ':') __CLASS_updateClassDef \"\$j\" \":\${tmp:1:1}$i\" ;;
          '-') __CLASS_updateClassDef \"\$j\" \"_\${tmp:1:1}$i\" ;;
          '_') __CLASS_updateClassDef \"\$j\" \"_\${tmp:1:1}$i\" ;;
          *)   error err
        esac
        if [[ \"\${tmp:1:1}\" == 'M' ]]; then
          eval \"${1}::\${j}() { ${i}::\${j} \\\"\\\$@\\\"; }\"
        fi
      done
    "
  done
}

ssalc() {
  __CLASS_CURRENT_CLASS=""
}

__CLASS_updateClassDef() {
  argsRequired 2 $#
  assertDoesNotContain "$1" ' '
  [ -z "$__CLASS_CURRENT_CLASS" ] && die "Can not modifiy classes outside class definitions!"
  eval "__CLASS_${__CLASS_CURRENT_CLASS}_PROPERTIES[$1]='$2'"
}

public:()    { __CLASS_CURRENT_ACCESS_RGHTS='+'; }
private:()   { __CLASS_CURRENT_ACCESS_RGHTS='-'; }
protected:() { __CLASS_CURRENT_ACCESS_RGHTS=':'; }

--() { __CLASS_updateClassDef "$@" "${__CLASS_CURRENT_ACCESS_RGHTS}I${__CLASS_CURRENT_CLASS}"; } # Private item
::() { __CLASS_updateClassDef "$@" "${__CLASS_CURRENT_ACCESS_RGHTS}M${__CLASS_CURRENT_CLASS}"; } # Public methode

__CLASS_createNewObject() {
  assertDoesNotContain "$1$2" ' '
  [ -n "$__CLASS_CURRENT_CLASS" ] && die "Can not create objects inside class definitions! (forgot ssalc?)"

  declare -f "$func" &> /dev/null && die "Object '$2' already exists!"

  local func tmp t size i I
  eval "size=\${#__CLASS_${1}_CONSTRUCTION_ORDER[@]}"
  declare -gA __CLASS_${1}_OBJECT_${2}
  for (( i = size - 1; i >= 0; i-- )); do
    eval "I=\"\${__CLASS_${1}_CONSTRUCTION_ORDER[\$i]}\""
    eval "t=\"\${__CLASS_${1}_PROPERTIES[\$I]}\""
    if [ -n "$t" ]; then
      if [[ "$1" == "$I" ]]; then
        [[ "${t:0:1}" == "-" ]] && die "Constructor of class '$I' is private"
        [[ "${t:0:1}" == "_" ]] && die "Constructor of class '$I' is private"
        [[ "${t:0:1}" == ":" ]] && die "Constructor of class '$I' is protected"
      fi

      func="${1}::${I}"
      declare -f "$func" &> /dev/null || die "Constructor of class '$I' is undefined or not a function"
      "$func" "__CLASS_accessOBJprivate $1 $2 ${I}" "${@:3}"
    fi
  done

  eval "$2() { __CLASS_accessOBJpublic $1 $2 $1 \"\$@\"; }"
}
