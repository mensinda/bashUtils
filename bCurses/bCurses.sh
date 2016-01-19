#!/bin/bash

class bCurses
  private:
    -- termInfo
    -- fullColorSupport

    -- mouseSupport

    -- children

    -- inputLoopRunning

  public:
    :: bCurses

    :: hideCursor
    :: showCursor

    :: append
    :: draw

    :: updateScreenSize

    :: startLoop
    :: stopLoop

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
  stty -echo
  # \x1b[?1049h  -- save term
  # \x1b[?1000h  -- mouse on
  # \x1b[?25l    -- hide cursor
  # \x1b[3k      -- clear term

  echo -ne "\x1b[?1049;1000h\x1b[?25l\x1b[2J\x1b[3J\x1b[1;1f"
}

bCurses::reset() {
  stty echo
  # \x1b[?1049l  -- restore term
  # \x1b[?1000l  -- mouse off
  # \x1b[?25h    -- show cursor

  echo -ne "\x1b[?1049;1000l\x1b[?25h\x1b[39;49m"
}

bCurses::startLoop() {
  argsRequired 4 $#
  $1 . inputLoopRunning true

  local c button posX posY str running ti i setSTR keys

  # Load keycodes int local vars
  $1  : termInfo ti
  $ti : setSTR setSTR

  for i in $setSTR; do
    [[ "${i:0:1}" != 'k' ]] && continue
    keys="$keys $i"
    eval "local $i"
    $ti : $i $i
  done

  while true; do
    $1 : inputLoopRunning running
    [[ "$running" != 'true' ]] && break

    # check resize
    posX=$COLUMNS
    posY=$LINES
    $ti . updateScreenSize
    (( posX != COLUMNS || posY != LINES )) && $4

    IFS= read -r -N1 -t 1 c
    (( $? != 0 )) && continue

    if [[ "$c" == $'\x1b' ]]; then
      str="$c"
      while IFS= read -r -N1 -t 0.001 c; do
        str="${str}${c}"
      done

      if [[ "${str:0:3}" == $'\x1b[M' ]]; then
        button="$( LC_CTYPE=C printf '%d' "'${str:3:1}" )"
        posX="$(   LC_CTYPE=C printf '%d' "'${str:4:1}" )"
        posY="$(   LC_CTYPE=C printf '%d' "'${str:5:1}" )"
        (( posX -= 32 ))
        (( posY -= 32 ))

        if (( (button & 64) != 0 )); then
          (( (button & 3) == 0 )) && button='WU'
          (( (button & 3) == 1 )) && button='WD'
        elif (( (button & 3) != 3 )); then
          button="MB$(( (button & 3) + 1 ))"
        else
          button="REL"
        fi

        $3 "$button" "$posX" "$posY"
        continue
      fi

      for i in $keys; do
        [[ "${!i}" != "$str" ]] && continue
        c="$i"
        break
      done
      [[ "$str" == $'\x1b'   && "$c" == "" ]] && c="ESC"
      [[ "$str" == $'\x1b[H' && "$c" == "" ]] && c="khome"
      [[ "$str" == $'\x1b[F' && "$c" == "" ]] && c="kend"
      [[ "$c" == "" ]] && c="!${str:1}"
    fi

    $2 "$c"
  done
}

bCurses::stopLoop() {
  $1 . inputLoopRunning false
}
