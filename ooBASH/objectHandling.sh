#!/bin/bash

__CLASS_checkExists() {
  local t
  eval "t=\"\${__CLASS_${1}_PROPERTIES[$2]}\""
  [ -z "$t" ] && return 1
  return 0
}

# Paramerters:
#  - 1: Class name
#  - 2: Object name
#  - 3: member
#  - 4: current visibility
# prints member type to stdout
__CLASS_checkVisibility() {
  __CLASS_checkExists "$1" "$3"
  (( $? != 0 )) && die "Class '$1' has no member '$2'"

  local t
  eval "t=\"\${__CLASS_${1}_PROPERTIES[$3]}\""

  # Check visibility
  if [[ "$4" == 'public' ]]; then
    [[ "${t:0:1}" == "-" ]] && die "Can not access private member '$3' of '$2'"
    [[ "${t:0:1}" == ":" ]] && die "Can not access protected member '$3' of '$2'"
  elif [[ "$4" == 'protected' ]]; then
    [[ "${t:0:1}" == "-" ]] && die "Can not access private member '$3' of '$2'"
  fi

  echo "${t:1:1}"
}

# Paramerters:
#  - 1: Class name
#  - 2: Object name
#  - 3: operator
#  - 4: member
#  - 5: current visibility
__CLASS_accessOBJ() {
  [ -n "$__CLASS_CURRENT_CLASS" ] && die "Can not access objects inside class definitions! (forgot ssalc?)"
  (( $# < 5 )) && die "$FUNCNAME needs at least 4 arguments"

  local func tmp t

  case "$3" in # operator
    .)
      #msg3 "ASDF"
      case "$(__CLASS_checkVisibility "$1" "$2" "$4" "$5")" in
        I)
          if (( $# >= 6 )); then
            eval "__CLASS_${1}_OBJECT_${2}[$4]='$6'"      # set
          else
            eval "echo \${__CLASS_${1}_OBJECT_${2}[$4]}"   # get
          fi
        ;;

        M)
          [[ "$4" == "$1"  ]] && die "Can not access constructor of object '$2' directly"
          [[ "$4" == "~$1" ]] && die "Can not access destructor of object '$2' directly"
          func="${1}::${4}"
          tmp="$(type -t "$func")" &> /dev/null
          [[ "$?" != 0 || "$tmp" != "function" ]] && die "Member '$4' of class '$1' is undefined or not a function"
          "$func" "__CLASS_accessOBJprivate $1 $2" "${@:6}"
        ;;

        *) die "Internal error: Unknown member type" ;;
      esac
      ;;

    destruct)
      unset -f "$2" # object name
      __CLASS_checkExists "$1" "~$1"
      if (( $? == 0 )); then
        func="${1}::~${1}"
        tmp="$(type -t "$func")" &> /dev/null
        [[ "$?" != 0 || "$tmp" != "function" ]] && die "Deconstructor of class '$1' is undefined or not a function"
        "$func" "__CLASS_accessOBJprivate $1 $2"
      fi
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
      eval "t=\"\${__CLASS_${1}_PROPERTIES[$4]}\""
      if   [[ "$5" == 'public' ]];    then [[ "${t:0:1}" != "+" ]] && return 1
      elif [[ "$5" == 'protected' ]]; then [[ "${t:0:1}" == "-" ]] && return 1
      fi
      return 0
      ;;

    name)      echo "$2" ;;
    classname) echo "$1" ;;
    *) die "Unknown operator '$3'" ;;
  esac

}

__CLASS_accessOBJpublic()    { __CLASS_accessOBJ "$1" "$2" "$3" "$4" 'public'    "${@:5}"; }
__CLASS_accessOBJprivate()   { __CLASS_accessOBJ "$1" "$2" "$3" "$4" 'private'   "${@:5}"; }
__CLASS_accessOBJprotected() { __CLASS_accessOBJ "$1" "$2" "$3" "$4" 'protected' "${@:5}"; }
