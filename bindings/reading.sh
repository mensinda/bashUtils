#!/bin/bash

BASHBinding::readReturnThread() {
  local chars
  while read -N 8 chars; do
    echo "CB: '$chars'"
    if [[ "$chars" = "\0\0\0\0\0\0\0\0" ]]; then
      msg1 "DONE CB"
      return
    fi
  done
}

BASHBinding::readCallbackThread() {
  local chars
  while read -N 8 chars; do
    echo "CB: '$chars'"
    if [[ "$chars" = "\0\0\0\0\0\0\0\0" ]]; then
      msg1 "DONE CB"
      return
    fi
  done
}
