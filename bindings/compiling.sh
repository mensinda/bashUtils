#!/bin/bash

BASHBinding::bbind_compile() {
  argsRequired 1 $#
  programRequired 'cmake'
  programRequired 'make'

  local path sourcePath
  path="$($1 . libPath)"
  sourcePath="$(dirname "${BASH_SOURCE[0]}")"

  msg1 "Compiling binding '$($1 classname)'"

  if [ ! -f "$sourcePath/src/tinycc/tcc" ]; then
    msg2 "Compiling TinyCC"
    pushd "$sourcePath/src/tinycc" &> /dev/null
    ./configure
    make
    (( $? != 0 )) && die "Failed to build TinyCC"
    popd &> /dev/null
  fi

  if [ -f "$path/bind.def" ]; then
    found "Binding definition file '$path/bind.def'"
    $1 . bbind_generateFiles "$path/bind.def"
  fi

  [ -e "$path/build" ] && rm -rf "$path/build"
  mkdir "$path/build"
  cd "$path/build"

  msg2 "Running CMake"
  cmake -DCMAKE_BUILD_TYPE=Debug ..
  (( $? != 0 )) && die "CMake error"

  msg2 "Running make"
  make
  (( $? != 0 )) && die "make error"

  [ ! -x 'binding' ] && die "Unable to find binding executable! (The main exe MUST be 'binding' for autocompile to work)"

  $1 . libPath    "$PWD/binding"
  $1 . isCompiled 'true'

  cd - &> /dev/null
}
