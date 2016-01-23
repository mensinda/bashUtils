#!/bin/bash

class bcBase
  protected:
    -- terminalSTR

    -- fgColor
    -- bgColor

    -- posX
    -- posY
    -- width
    -- height

    -- children

    -- visible

    -- updated
    -- parent

    :: drawObjectAndChildren

  public:
    :: setColors
    :: setPos
    :: setPosRel
    :: setSize

    :: hide
    :: show

    :: getIsVisible
    :: getPos
    :: getSize
    :: getColorSTR

    :: resizeFullscreen
    :: center
    :: centerRel

    :: genWinSTR

    :: append
ssalc

bcBase::append() {
  argsRequired 2 $#
  local t
  $1 : children t
  $1 . children "$t $2"
}

bcBase::drawObjectAndChildren() {
  local t i visible

  $1 : visible visible
  [[ "$visible" != 'true' ]] && return

  $1 : terminalSTR t
  echo -ne "$t"

  $1 : children t
  for i in $t; do
    $i . draw
  done
}

bcBase::setPos() {
  argsRequired 3 $#

  local x=$2 y=$3

  (( x > COLUMNS )) && x=$COLUMNS
  (( y > LINES   )) && y=$LINES

  $1 . posX $x
  $1 . posY $y
  $1 . updated true
}

bcBase::setPosRel() {
  local x y p
  $1 : parent p

  $p . getPos x y

  (( x += $2 ))
  (( y += $3 ))

  (( x > COLUMNS )) && x=$COLUMNS
  (( y > LINES   )) && y=$LINES

  $1 . posX $x
  $1 . posY $y
  $1 . updated true
}

bcBase::setSize() {
  argsRequired 3 $#

  local x y w=$2 h=$3
  $1 : posX x
  $1 : posY y

  (( (w + x) > COLUMNS + 1 )) && w=$(( $COLUMNS - x + 1 ))
  (( (h + y) > LINES   + 1 )) && h=$(( $LINES   - y + 1 ))

  $1 . width  $w
  $1 . height $h
  $1 . updated true
}

bcBase::resizeFullscreen() {
  $1 . setPos  1 1
  $1 . setSize "$COLUMNS" "$LINES"
}

bcBase::center() {
  local w h
  $1 : width  w
  $1 : height h
  $1 . setPos $(( COLUMNS / 2 - w / 2 )) $(( LINES / 2 - h / 2 ))
}

bcBase::centerRel() {
  local w h p pX pY pW pH
  $1 : parent p
  $1 : width  w
  $1 : height h
  $p . getPos  pX pY
  $p . getSize pW pH
  $1 . setPos $(( pX + pW / 2 - w / 2 )) $(( pY + pH / 2 - h / 2 ))
}

bcBase::setColors() {
  argsRequired 3 $#

  local i j=2

  for i in fgColor bgColor; do
    if [ -n "${!j}" ]; then
      case "${!j}" in
        black|BLACK|Black)       $1 . $i "\x1b[$((j+1))0m" ;; # 3x fg; 4x bg
        red|RED|Red)             $1 . $i "\x1b[$((j+1))1m" ;;
        green|GREEN|Green)       $1 . $i "\x1b[$((j+1))2m" ;;
        yellow|YELLOW|Yellow)    $1 . $i "\x1b[$((j+1))3m" ;;
        blue|BLUE|Blue)          $1 . $i "\x1b[$((j+1))4m" ;;
        magenta|MAGENTA|Magenta) $1 . $i "\x1b[$((j+1))5m" ;;
        cyan|CYAN|Cyan)          $1 . $i "\x1b[$((j+1))6m" ;;
        white|WHITE|White)       $1 . $i "\x1b[$((j+1))7m" ;;
        *) $1 . $i "\x1b[$((j+1))8;${!j}m" ;;
      esac
    else
      $1 . $i ''
    fi
    (( j++ ))
  done
  $1 . updated true
}

bcBase::hide() {
  $1 . visible false
}

bcBase::show() {
  $1 . visible true
}

bcBase::getIsVisible() {
  argsRequired 2 $#
  $1 : visible $2
}

bcBase::getPos() {
  argsRequired 3 $#
  $1 : posX $2
  $1 : posY $3
}

bcBase::getSize() {
  argsRequired 3 $#
  $1 : width  $2
  $1 : height $3
}

bcBase::getColorSTR() {
  argsRequired 3 $#
  $1 : fgColor $2
  $1 : bgColor $3
}
