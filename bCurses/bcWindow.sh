#!/bin/bash

class bcWindow
  private:
    -- windowSTR
    -- parent

    -- fgColor
    -- bgColor

    -- posX
    -- posY
    -- width
    -- height

    -- updated

    :: genWinSTR

  public:
    :: bcWindow

    :: setColors
    :: setPos
    :: setSize

    :: draw

ssalc

bcWindow::bcWindow() {
  argsRequired 6 $#

  $1 . parent  "$2"
  $2 . updateScreenSize
  $2 . append "$($1 name)"

  $1 . setPos  "$3" "$4"
  $1 . setSize "$5" "$6"
}

bcWindow::genWinSTR() {
  $1 . updated false
  local i j str fgColor bgColor width height posX posY

  # Store class vars in local vars
  for i in fgColor bgColor posX posY width height; do
    $1 : $i $i
  done

  # Clear the screen
  str="${fgColor}${bgColor}"

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

bcWindow::draw() {
  argsRequired 1 $#
  local t
  $1 : updated t
  [[ "$t" == "true" ]] && $1 . genWinSTR
  $1 : windowSTR t
  echo -ne "$t"
}
