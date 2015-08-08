#!/bin/bash

__CLASS_CURRENT_CLASS=""
__CLASS_CURRENT_ACCESS_RGHTS=""

class() {
  argsRequired 1 $#
  assertDoesNotContain "$1" ' '
  eval "$1() { __CLASS_createNewObject $1 \$*; }"
  declare -gA __CLASS_${1}_PROPERTIES
  __CLASS_CURRENT_CLASS="$1"
  __CLASS_CURRENT_ACCESS_RGHTS='-'
}

ssalc() {
  __CLASS_CURRENT_CLASS=""
}

__updateClassDef() {
  argsRequired 2 $#
  assertDoesNotContain "$1" ' '
  [ -z "$__CLASS_CURRENT_CLASS" ] && die "Can not modifiy classes outside class definitions!"
  eval "__CLASS_${__CLASS_CURRENT_CLASS}_PROPERTIES[$1]='$2'"
}

public:()    { __CLASS_CURRENT_ACCESS_RGHTS='+'; }
private:()   { __CLASS_CURRENT_ACCESS_RGHTS='-'; }
protected:() { __CLASS_CURRENT_ACCESS_RGHTS=':'; }

--() { __updateClassDef "$@" "${__CLASS_CURRENT_ACCESS_RGHTS}I"; } # Private item
::() { __updateClassDef "$@" "${__CLASS_CURRENT_ACCESS_RGHTS}M"; } # Public methode

__CLASS_createNewObject() {
  assertDoesNotContain "$1$2" ' '
  [ -n "$__CLASS_CURRENT_CLASS" ] && die "Can not create objects inside class definitions! (forgot ssalc?)"

  local func tmp t
  eval "t=\"\${__CLASS_${1}_PROPERTIES[${1}]}\""
  if [ -n "$t" ]; then
    [[ "${t:0:1}" == "-" ]] && die "Constructor of class '$1' is private"
    [[ "${t:0:1}" == ":" ]] && die "Constructor of class '$1' is protected"
    declare -gA __CLASS_${1}_OBJECT_${2}

    func="${1}::${1}"
    tmp="$(type -t "$func")" &> /dev/null
    [[ "$?" != 0 || "$tmp" != "function" ]] && die "Member '$4' of class '$1' is undefined or not a function"
    "$func" "__CLASS_accessOBJprivate $1 $2" "${@:3}"
  else
    declare -gA __CLASS_${1}_OBJECT_${2}
  fi

  eval "$2() { __CLASS_accessOBJpublic $1 $2 \"\$@\"; }"
}
