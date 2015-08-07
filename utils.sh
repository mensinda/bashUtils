#!/bin/bash

die() {
  error   "$@"

  local i=0 trace temp max_line=0 max_func=0 max_file=0 line func file
  typeset -A trace
  error "Backtrace:"
  while true; do
    temp="$(caller $i)"
    (( $? != 0 )) && break
    line="${temp/% +([^ ]) +([^ ])/}"
    func="${temp/#+([0-9]) /}"
    func="${func/% +([^ ])/}"
    file="${temp/#+([0-9]) +([^ ]) /}"

    (( max_line < ${#line} )) && max_line=${#line}
    (( max_func < ${#func} )) && max_func=${#func}
    (( max_file < ${#file} )) && max_file=${#file}

    trace[$i,0]="$line"
    trace[$i,1]="$func"
    trace[$i,2]="$file"
    (( i++ ))
  done

  local j s1 s2
  for (( j=0; j < i; j++ )); do
    line="${trace[$j,0]}"
    func="${trace[$j,1]}"
    file="${trace[$j,2]}"
    s1="$(printNumChar $(( max_file - ${#file} )) " ")"
    s2="$(printNumChar $(( max_line - ${#line} )) " ")"
    error "  ${file}${s1} \x1b[0mLine\x1b[1m ${line}${s2} \x1b[0mFunction\x1b[1m \x1b[36m$func"
  done

  exit 1
}

die_badArg() {
  argsRequired 2 $#
  die "'$2' is an invalid parameter for Function ${FUNCNAME[1]} (arg $1)"
}

die_parseError() {
  argsRequired 1 $#
  die "Function ${FUNCNAME[1]} failed to parse file '$2'"
}

die_expected() {
  argsRequired 2 $#
  die "Function ${FUNCNAME[1]}: Expected '$1' but got '$2' instead"
}

argsRequired() {
  (( $# != 2 ))  && argsRequired 2 $#
  (( $2 == $1 )) && return
  die "'${FUNCNAME[1]}' requires $1 argument(s) but $2 where provided"
}

programRequired() {
  argsRequired 1 $#
  which "$1" &> /dev/null
  (( $? == 0 )) && return
  die "'${FUNCNAME[1]}' requires the program '$1' (not in \$PATH)"
}

fileRequired() {
  argsRequired 2 $#
  if [ ! -f "$1" ]; then
    case "$2" in
      create)  touch "$2" ;;
      require) die "Required file '$1' does not exist" ;;
      *)       die_badArg 2 "$2" ;;
    esac
    warning "File $1 does not exist"
    touch "$1"
  fi
}

assertEqual() {
  argsRequired 2 $#
  [[ "$1" != "$2" ]] && die_expected "$2" "$1"
}

assertDoesNotContain() {
  argsRequired 2 $#
  local t="${1//$2/}"
  [[ "$1" != "$t" ]] && die "String '$1' must not contain '$2'"
}
