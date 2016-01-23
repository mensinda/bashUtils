#!/bin/bash

declare -f "bcBase" &> /dev/null || source "${BASH_SOURCE%/*}/bcBase.sh"

class bcText bcBase
  private:
    -- textSTR

    :: genTextSTR

  public:
    :: bcText
    :: draw

    :: setText
ssalc

bcText::bcText() {
  (( $# != 2 )) && argsRequired 4 $#

  local fgColor bgColor

  $1 . parent  "$2"
  $2 . append "$($1 name)"
  $2 . getColorSTR fgColor bgColor

  $1 . fgColor "$fgColor"
  $1 . bgColor "$bgColor"
  $1 . show

  (( $# == 2 )) && return

  $1 . setPosRel "$3" "$4"
}

bcText::genTextSTR() {
  local str fgColor bgColor posX posY textSTR
  $1 . updated false

  for i in fgColor bgColor posX posY textSTR; do
    $1 : $i $i
  done

  str="${fgColor}${bgColor}\x1b[${posY};${posX}f${textSTR}"

  $1 . terminalSTR "$str"
}

bcText::draw() {
  $1 : updated t
  [[ "$t" == "true" ]] && $1 . genTextSTR

  $1 . drawObjectAndChildren
}

bcText::setText() {
  $1 . updated true
  local i str num
  for i in "${@:2}"; do
    if [[ "${i:0:1}" == '@' && "${i:$(( ${#i} - 1 )):1}" == '@' ]]; then
      case "${i:1:$(( ${#i} - 2 ))}" in
        off|OFF|Off)                   num=0  ;;
        bold|BOLD|Bold)                num=1  ;;
        italic|ITALIC|Italic)          num=3  ;;
        underline|UNDERLINE|Underline) num=4  ;;
        blink|BLINK|Blink)             num=5  ;;
        inverse|INVERSE|Inverse)       num=7  ;;
        black|BLACK|Black)             num=30 ;;
        red|RED|Red)                   num=31 ;;
        green|GREEN|Green)             num=32 ;;
        yellow|YELLOW|Yellow)          num=33 ;;
        blue|BLUE|Blue)                num=34 ;;
        magenta|MAGENTA|Magenta)       num=35 ;;
        cyan|CYAN|Cyan)                num=36 ;;
        white|WHITE|White)             num=37 ;;
      esac
      str="${str}\x1b[${num}m"
    else
      str="${str}${i}"
    fi
  done

  $1 . textSTR "$str"
}
