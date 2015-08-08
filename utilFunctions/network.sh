#!/bin/bash

downloadFile() {
  argsRequired 3 $#
  programRequired 'wget'

  wget -O "$2" "$1" &> /dev/null
  RET=$?
  (( RET == 0 )) && return 0
  case "$3" in
    die)     die     "Failed to download file '$1'"              ;;
    warning) warning "Failed to download file '$1'"; return $RET ;;
    *)       error   "Failed to download file '$1'"; return $RET ;;
  esac
}
