#!/bin/bash

class bCurses
  private:
    -- termInfo
    -- fullColorSupport

    -- mouseSupport

    -- children

  public:
    :: bCurses

    :: hideCursor
    :: showCursor
    :: colors

    :: append
    :: draw

    :: updateScreenSize

    :: init
    :: reset
ssalc

bCurses::bCurses() {
  argsRequired 2 $#
  [[ "$($2 classname)" != "bTermInfo" ]] && die "Expected bTermInfo object"

  local temp

  $2 : colors temp
  if (( temp >= 256 )); then
    $1 . fullColorSupport true
  else
    $1 . fullColorSupport false
  fi

  $1 . termInfo "$2"
}

bCurses::append() {
  argsRequired 2 $#
  local t
  $1 : children t
  $1 . children "$t $2"
}

bCurses::draw() {
  local t i
  $1 : children t

  for i in $t; do
    $i . draw
  done
}

bCurses::updateScreenSize() {
  local ti
  $1 : termInfo ti
  $ti . updateScreenSize
}

bCurses::hideCursor() {
  echo -ne "\x1b[?25l"
}

bCurses::showCursor() {
  echo -ne "\x1b[?25h"
}

bCurses::init() {
  # \x1b[?1049h  -- save term
  # \x1b[?1000h  -- mouse on
  # \x1b[?25l    -- hide cursor
  # \x1b[3k      -- clear term

  echo -ne "\x1b[?1049h\x1b[?1000h\x1b[?25l\x1b[2J\x1b[3J\x1b[1;1f"
}

bCurses::reset() {
  # \x1b[?1049l  -- restore term
  # \x1b[?1000l  -- mouse off
  # \x1b[?25h    -- show cursor

  echo -ne "\x1b[?1049l\x1b[?1000l\x1b[?25h\x1b[39;49m"
}

bCurses::colors() {
  local i
  for (( i=0; i<256; i++ )); do
    echo -ne "\x1b[48;5;${i}m  "
  done
}
