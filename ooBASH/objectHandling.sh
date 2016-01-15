#!/bin/bash

__CLASS_checkExists() {
  local t
  eval "t=\"\${__CLASS_${1}_PROPERTIES[$2]}\""
  [ -z "$t" ] && return 1
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

  local func tmp t i I size

  case "$3" in # operator
    .)
      __CLASS_checkVisibility "$6" "$4" "$5" t
      (( $? != 0 )) && die "Can not access member '$4' of class '$1' (object: '$2')"
      case "${t:0:1}" in
        I)
          if (( $# >= 7 )); then
            eval "__CLASS_${1}_OBJECT_${2}[$4]='$7'"       # set
          else
            eval "echo \${__CLASS_${1}_OBJECT_${2}[$4]}"   # get
          fi
        ;;

        M)
          [[ "$4" == "$1"  ]] && die "Can not access constructor of object '$2' directly"
          [[ "$4" == "~$1" ]] && die "Can not access destructor of object '$2' directly"
          func="${1}::${4}"
          declare -f "$func" &> /dev/null || die "Member '$4' of class '$1' is undefined or not a function"
          "$func" "__CLASS_accessOBJprivate $1 $2 ${t:1}" "${@:7}"
          return $?
        ;;

        *) die "Internal error: Unknown member type" ;;
      esac
      ;;

    :)
      __CLASS_checkVisibility "$6" "$4" "$5" t
      (( $? != 0 )) && die "Can not access member '$4' of class '$1' (object: '$2')"
      case "${t:0:1}" in
        I)
          if (( $# != 7 )); then
            die "No local variable specified"
          else
            eval "$7=\${__CLASS_${1}_OBJECT_${2}[$4]}"   # get
          fi
        ;;

        M)
          die "Can only run get on attributes"
        ;;

        *) die "Internal error: Unknown member type" ;;
      esac
      ;;


    destruct)
      unset -f "$2" # object name
      eval "size=\${#__CLASS_${1}_CONSTRUCTION_ORDER[@]}"
      for (( i = size - 1; i >= 0; i-- )); do
        eval "I=\"\${__CLASS_${1}_CONSTRUCTION_ORDER[\$i]}\""
        __CLASS_checkExists "$1" "~$I"
        if (( $? == 0 )); then
          func="${1}::~${I}"
          declare -f "$func" &> /dev/null || die "Deconstructor of class '$I' is undefined or not a function"
          "$func" "__CLASS_accessOBJprivate $1 $2 $I"
        fi
      done
      unset "__CLASS_${1}_OBJECT_${2}"
      ;;

    hasFunc)
      eval "t=\"\${__CLASS_${1}_PROPERTIES[$4]}\""
      [[ "${t:1:1}" == 'M' ]] && return 0
      return 1
      ;;
    hasAttr)
      eval "t=\"\${__CLASS_${1}_PROPERTIES[$4]}\""
      [[ "${t:1:1}" == 'I' ]] && return 0
      return 1
      ;;

    isVisible)
      __CLASS_checkVisibility "$6" "$4" "$5" t
      return $?
      ;;

    name)      echo "$2" ;;
    classname) echo "$1" ;;
    *) die "Unknown operator '$3'" ;;
  esac

}

__CLASS_accessOBJpublic()    { __CLASS_accessOBJ "$1" "$2" "$4" "$5" 'public'  "$3" "${@:6}"; }
__CLASS_accessOBJprivate()   { __CLASS_accessOBJ "$1" "$2" "$4" "$5" 'private' "$3" "${@:6}"; }
