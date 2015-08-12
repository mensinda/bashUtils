#!/bin/bash

BASHBinding::bbind_readReturn() {
  local char
  while read -N 1 char; do
    case "${char}" in
      E) return ;;
      *) warning "Unknown command -- return -- '$char'"
    esac
  done
}

BASHBinding::bbind_readCallback() {
  local char size fName fifoDir

  fifoDir=$($1 . fifoDir)

  [ -f "$fifoDir/tmp_func_def" ] && die "Temporary function definition file already exists"

  while read -N 1 char; do
    case "${char}" in
      I)
        read -d ';' size
        read -N $size fName
        $1 hasFunc "${fName/%:*}"
        if (( $? != 0 )); then
          error "Function '${fName/%:*}' missing in binding class definition"
          echo -n '0' 1>&4
          continue
        fi
        echo -n '1' 1>&4
        # It is impossible to eval the functions into existence here because we are in a subshell :(
        echo "$fName" >> "$fifoDir/tmp_func_def"
        ;;
      i)
        read -d ';' size
        $1 . isInit 'true'
        FIFOcontinue "$fifoDir/wait_init_FIFO"
        msg2 "Init done"
        ;;
      E) return ;;
      *) warning "Unknown command -- call -- '$char'"
    esac
  done
}
