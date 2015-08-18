#!/bin/bash

BASHBinding::bbind_readReturn() {
  local char size data temp metadata fifoDir

  fifoDir="$($1 . fifoDir)"

  while read -N 1 char; do
    case "${char}" in
      R)
        read -d ';' size
        read -N $size data

        temp="${data/#+([0-9])|}"
        temp="${temp/%;*}"

        metadata="${data/#*([0-9|]);}"
        metadata="${metadata:0:$temp}"
        echo -n "$data" 1>"$fifoDir/$metadata"
        ;;
      E) return ;;
      *) warning "Unknown command -- return -- '$char'"
    esac
  done
}

BASHBinding::bbind_readCallback() {
  local char size fName fifoDir

  fifoDir="$($1 . fifoDir)"

  [ -f "$fifoDir/tmp_func_def" ] && die "Temporary function definition file already exists"

  while read -N 1 char; do
    case "${char}" in
      I)
        read -d ';' size
        read -N $size fName
        $1 hasFunc "${fName/%#*}"
        if (( $? != 0 )); then
          error "Function '${fName/%#*}' missing in binding class definition"
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

BASHBinding::bbind_sendCALL() {
  argsRequired 3 $#
  local data mSize isPTR out counter=0

  echo -n "$3" 1>&100

  data="$(<"$2")"
  data="${data/#+([0-9])|}"

  mSize="${data/%;*}"
  data="${data/#+([0-9]);}"
  data="${data:$mSize}"

  while [ -n "$data" ]; do
    isPTR="${data/%,*}"
    data="${data/#+([0-9]),}"
    mSize="${data/%:*}"
    data="${data/#+([0-9]):}"
    out="${data:0:$mSize}"
    data="${data:$mSize}"

    [[ "$isPTR" == '1' ]] && out=$"\x01PTR$out"

    eval "OUT_$counter='$out'"
    (( counter++ ))
  done

  [ -e "$2" ] && rm "$2"
}
