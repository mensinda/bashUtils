#!/bin/bash

__CLASS_checkExists() {
  local __t
  eval "__t=\"\${__CLASS_${1}_PROPERTIES[$2]}\""
  [ -z "$__t" ] && return 1
  return 0
}

# Paramerters:
#  - 1: Class name
#  - 2: member
#  - 3: current visibility
# prints member type to stdout
__CLASS_checkVisibility() {
  __CLASS_checkExists "$1" "$2"
  (( $? != 0 )) && die "Class '$1' has no member '$2'"

  local T tmp
  eval "T=\"\${__CLASS_${1}_PROPERTIES[$2]}\""
  eval "$4='${T:1}'"

  # Check visibility
  case "$3" in
    private)
      tmp="${T:2}"
      [[ "${T:0:1}" == "_" && "$tmp" != "$1" ]] && return 1 ;;
    public)
      [[ "${T:0:1}" == "-" ]] && return 1
      [[ "${T:0:1}" == ":" ]] && return 1 ;;
    *) die "Internal error: unknown visibility '$3'" ;;
  esac

  return 0
}

# Paramerters:
#  - 1: Class name
#  - 2: Object name
#  - 3: operator
#  - 4: member
#  - 5: current visibility
#  - 6: current class
__CLASS_accessOBJ() {
  [ -n "$__CLASS_CURRENT_CLASS" ] && die "Can not access objects inside class definitions! (forgot ssalc?)"
  (( $# < 5 )) && die "$FUNCNAME needs at least 4 arguments"

  local __func __t

  case "$3" in # operator
    .)
      __CLASS_checkVisibility "$6" "$4" "$5" __t
      (( $? != 0 )) && die "Can not access member '$4' of class '$1' (object: '$2')"
      case "${__t:0:1}" in
        I)
          if (( $# >= 7 )); then
            eval "__CLASS_${1}_OBJECT_${2}[$4]=\"\$7\""         # set
          else
            eval "echo -n \"\${__CLASS_${1}_OBJECT_${2}[$4]}\"" # get
          fi
        ;;

        M)
          [[ "$4" == "$1"  ]] && die "Can not access constructor of object '$2' directly"
          [[ "$4" == "~$1" ]] && die "Can not access destructor of object '$2' directly"
          __func="${1}::${4}"
          declare -f "$__func" &> /dev/null || die "Member '$4' of class '$1' is undefined or not a function"
          "$__func" "__CLASS_accessOBJprivate $1 $2 ${__t:1}" "${@:7}"
          return $?
        ;;

        *) die "Internal error: Unknown member type" ;;
      esac
      ;;

    :)
      __CLASS_checkVisibility "$6" "$4" "$5" __t
      (( $? != 0 )) && die "Can not access member '$4' of class '$1' (object: '$2')"
      case "${__t:0:1}" in
        I)
          (( $# != 7 )) && die "No local variable specified"
          eval "$7=\"\${__CLASS_${1}_OBJECT_${2}[$4]}\""   # get
        ;;

        M) die "Can only run get on attributes"
      esac
      ;;

    ::)
      __CLASS_checkVisibility "$6" "$4" "$5" __t
      (( $? != 0 )) && die "Can not access member '$4' of class '$1' (object: '$2')"
      case "${__t:0:1}" in
        I)
          (( $# != 7 )) && die "No local variable specified"
          eval "$7=\"${7}\${__CLASS_${1}_OBJECT_${2}[$4]}\""   # get
        ;;

        M) die "Can only run get on attributes" ;;
      esac
      ;;


    destruct)
      unset -f "$2" # object name
      local tmp i I size
      eval "size=\${#__CLASS_${1}_CONSTRUCTION_ORDER[@]}"
      for (( i = size - 1; i >= 0; i-- )); do
        eval "I=\"\${__CLASS_${1}_CONSTRUCTION_ORDER[\$i]}\""
        __CLASS_checkExists "$1" "~$I"
        if (( $? == 0 )); then
          __func="${1}::~${I}"
          declare -f "$__func" &> /dev/null || die "Deconstructor of class '$I' is undefined or not a function"
          "$__func" "__CLASS_accessOBJprivate $1 $2 $I"
        fi
      done
      unset "__CLASS_${1}_OBJECT_${2}"
      ;;

    hasFunc)
      eval "__t=\"\${__CLASS_${1}_PROPERTIES[$4]}\""
      [[ "${__t:1:1}" == 'M' ]] && return 0
      return 1
      ;;
    hasAttr)
      eval "__t=\"\${__CLASS_${1}_PROPERTIES[$4]}\""
      [[ "${__t:1:1}" == 'I' ]] && return 0
      return 1
      ;;

    isVisible)
      __CLASS_checkVisibility "$6" "$4" "$5" __t
      return $?
      ;;

    name)      echo -n "$2" ;;
    classname) echo -n "$1" ;;
    *) die "Unknown operator '$3'" ;;
  esac

}

__CLASS_accessOBJpublic()    { __CLASS_accessOBJ "$1" "$2" "$4" "$5" 'public'  "$3" "${@:6}"; }
__CLASS_accessOBJprivate()   { __CLASS_accessOBJ "$1" "$2" "$4" "$5" 'private' "$3" "${@:6}"; }
