#!/bin/bash

FIFOwait() {
  argsRequired 1 $#
  if [ -p "$1" ]; then
    rm "$1"
    return
  fi
  [ -e "$1" ] && die "File '$1' already exsits! (and is not a FIFO)"
  mkfifo "$1"
  while (( 0 == 1 )); do false; done < "$1"
  rm "$1"
}

FIFOcontinue() {
  argsRequired 1 $#
  [ ! -e "$1" ] && mkfifo "$1"
  [ ! -p "$1" ] && die "File '$1' is not a FIFO"
  echo '' &> "$1"
}
