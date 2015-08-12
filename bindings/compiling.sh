#!/bin/bash

BASHBinding::bbind_compile() {
  argsRequired 1 $#
  programRequired 'cmake'
  programRequired 'make'

  local compiled path
  compiled="$($1 . isCompiled)"
  path="$($1 . libPath)"
  [[ "$compiled" == 'true' ]] && return

  msg1 "Compiling binding '$($1 classname)'"

  if [ -f "$path/bind.def" ]; then
    found "Binding definition file '$path/bind.def'"
    $1 . bbind_generateFiles "$path/bind.def"
  fi

  [ -e "$path/build" ] && rm -rf "$path/build"
  mkdir "$path/build"
  cd "$path/build"

  msg2 "Running CMake"
  cmake ..
  (( $? != 0 )) && die "CMake error"

  msg2 "Running make"
  make
  (( $? != 0 )) && die "make error"

  [ ! -x 'binding' ] && die "Unable to find binding executable! (The main exe MUST be 'binding' for autocompile to work)"

  $1 . libPath    "$PWD/binding"
  $1 . isCompiled 'true'

  cd - &> /dev/null
}
