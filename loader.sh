#!/bin/bash

shopt -s extglob

loadBashUtils() {
  local i j
  for i in ooBASH utilFunctions bindings bCurses; do
    for j in "$(dirname "${BASH_SOURCE[0]}")/$i/"*.sh; do
      source "$j"
    done
  done
}
