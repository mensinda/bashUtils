#!/bin/bash

BASHBinding::BASHBinding() {
  argsRequired 3 $#

  [ ! -d "$(readlink -f "$3")" ] && die "'$3' is not a directory"

  [ ! -e "$2" ] && die "Path '$2' does not exist"
  if [ -d "$2" ]; then
    $1 . isCompiled 'false'
    [ ! -f "$2/CMakeLists.txt" ] && die "unable to find build files"
  elif [ -f "$2" ]; then
    $1 . isCompiled 'true'
  else
    die "Invalid binding path '$2'"
  fi

  $1 . libPath   "$(readlink -f "$2")"
  $1 . fifoDir   "$(readlink -f "$3")"
  $1 . isStarted 'false'

  local i
  for i in {binding,shell}{CALL,RETURN}; do
    [ -e "$(readlink -f "$3")/$i" ] && rm "$(readlink -f "$3")/$i"
    mkfifo "$(readlink -f "$3")/$i"
    (( $? != 0 )) && die "Failed to create FIFO '$(readlink -f "$3")/$i'"
  done
}

BASHBinding::~BASHBinding() {
  argsRequired 1 $#
  local i dir started
  dir="$($1 . fifoDir)"
  started="$($1 . isStarted)"

  for i in {binding,shell}{CALL,RETURN}; do
    [ -e "$dir/$i" ] && rm "$dir/$i"
  done

  [[ "$started" == 'true' ]] && $1 . stop
}
