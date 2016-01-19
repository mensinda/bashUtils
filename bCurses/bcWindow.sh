#!/bin/bash

class bcWindow
  private:
    -- windowSTR
    -- parent

    -- fgColor
    -- bgColor
    -- shadowColor

    -- posX
    -- posY
    -- width
    -- height

    -- shadowOX
    -- shadowOY

    -- updated

    -- children

    :: genWinSTR

  public:
    :: bcWindow

    :: setColors
    :: setPos
    :: setSize

    :: setShadow

    :: getPos
    :: getSize

    :: resizeFullscreen
    :: center

    :: append

    :: draw

ssalc

bcWindow::bcWindow() {
  (( $# != 2 )) && argsRequired 6 $#

  $1 . parent  "$2"
  $2 . append "$($1 name)"

  $1 . shadowOX 0
  $1 . shadowOY 0

  (( $# == 2 )) && return

  $1 . setPos  "$3" "$4"
  $1 . setSize "$5" "$6"
}

bcWindow::append() {
  argsRequired 2 $#
  local t
  $1 : children t
  $1 . children "$t $2"
}

bcWindow::genWinSTR() {
  $1 . updated false
  local i j str fgColor bgColor posShadowX shadowColor width height posX posY shadowOX shadowOY

  # Store class vars in local vars
  for i in fgColor bgColor shadowColor posX posY width height shadowOX shadowOY; do
    local $i
    $1 : $i $i
  done

  (( posShadowX = posX + shadowOX ))

  if (( shadowOY != 0 || shadowOX != 0 )); then
    str="$shadowColor"
    for (( i=0; i < height; i++ )); do
      (( j = i + posY + shadowOY ))
      str="${str}\x1b[${j};${posShadowX}f\x1b[${width}X"
    done
  fi

  str="${str}${fgColor}${bgColor}"

  for (( i=0; i < height; i++ )); do
    (( j = i + posY ))
    str="${str}\x1b[${j};${posX}f\x1b[${width}X"
  done

  str="${str}\x1b[0m"
  $1 . windowSTR "$str"
}

bcWindow::setPos() {
  argsRequired 3 $#

  local x=$2 y=$3

  (( x > COLUMNS )) && x=$COLUMNS
  (( y > LINES   )) && y=$LINES

  $1 . posX $x
  $1 . posY $y
  $1 . updated true
}

bcWindow::setSize() {
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

bcWindow::setShadow() {
  argsRequired 4 $#

  case "$2" in
    black|BLACK|Black)       $1 . shadowColor "\x1b[40m" ;; # 3x fg; 4x bg
    red|RED|Red)             $1 . shadowColor "\x1b[41m" ;;
    green|GREEN|Green)       $1 . shadowColor "\x1b[42m" ;;
    yellow|YELLOW|Yellow)    $1 . shadowColor "\x1b[43m" ;;
    blue|BLUE|Blue)          $1 . shadowColor "\x1b[44m" ;;
    magenta|MAGENTA|Magenta) $1 . shadowColor "\x1b[45m" ;;
    cyan|CYAN|Cyan)          $1 . shadowColor "\x1b[46m" ;;
    white|WHITE|White)       $1 . shadowColor "\x1b[47m" ;;
    *) $1 . shadowColor "\x1b[48;${2}m" ;;
  esac

  $1 . shadowOX "$3"
  $1 . shadowOY "$4"
  $1 . updated true
}

bcWindow::resizeFullscreen() {
  $1 . setPos  1 1
  $1 . setSize "$COLUMNS" "$LINES"
}

bcWindow::center() {
  local w h
  $1 : width  w
  $1 : height h
  $1 . setPos $(( COLUMNS / 2 - w / 2 )) $(( LINES / 2 - h / 2 ))
}

bcWindow::setColors() {
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

bcWindow::getPos() {
  argsRequired 3 $#
  $1 : posX $2
  $1 : posY $3
}

bcWindow::getSize() {
  argsRequired 3 $#
  $1 : width  $2
  $1 : height $3
}


bcWindow::draw() {
  argsRequired 1 $#
  local t i
  $1 : updated t
  [[ "$t" == "true" ]] && $1 . genWinSTR
  $1 : windowSTR t
  echo -ne "$t"

  $1 : children t
  for i in $t; do
    $i . draw
  done
}
