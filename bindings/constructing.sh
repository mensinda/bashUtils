#!/bin/bash

BASHBinding::BASHBinding() {
  argsRequired 3 $#

  [ ! -d "$(readlink -f "$3")" ] && die "'$3' is not a directory"

  [ ! -e "$2" ] && die "Path '$2' does not exist"
  [ ! -d "$2" ] && die "Invalid binding path '$2'"

  $1 . bbind_libPath   "$(readlink -f "$2")"
  $1 . bbind_fifoDir   "$(readlink -f "$3")"
  $1 . bbind_isStarted 'false'
  $1 . bbind_isInit    'false'

  if [ -x "$(readlink -f "$2")/build/binding" ]; then
    $1 . bbind_execPath "$(readlink -f "$2")/build/binding"
    $1 . bbind_isCompiled true
  else
    $1 . bbind_isCompiled false
  fi

  local i
  for i in {binding,shell}CALL; do
    [ -e "$(readlink -f "$3")/$i" ] && rm "$(readlink -f "$3")/$i"
    mkfifo "$(readlink -f "$3")/$i"
    (( $? != 0 )) && die "Failed to create FIFO '$(readlink -f "$3")/$i'"
  done
}

BASHBinding::~BASHBinding() {
  argsRequired 1 $#
  local i dir started
  dir="$($1 . bbind_fifoDir)"
  started="$($1 . bbind_isStarted)"

  [[ "$started" == 'true' ]] && $1 . bbind_stop

  for i in {binding,shell}CALL; do
    [ -e "$dir/$i" ] && rm "$dir/$i"
  done
}

BASHBinding::bbind_getIsInit() {
  if [[ "$($1 . bbind_isInit)" == 'true' ]]; then
    return 0
  else
    return 1
  fi
}

BASHBinding::bbind_getIsCompiled() {
  if [[ "$($1 . bbind_isCompiled)" == 'true' ]]; then
    return 0
  else
    return 1
  fi
}
