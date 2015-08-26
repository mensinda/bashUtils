#!/bin/bash

BASHBinding::bbind_readCallback() {
  local char size fName fifoDir
  local idLen id metadataSize metadata isPTR argLen arg fName tmp

  declare -a argv

  fifoDir="$($1 . bbind_fifoDir)"

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
        $1 . bbind_isInit 'true'
        FIFOcontinue "$fifoDir/wait_init_FIFO"
        ;;
      C)
        read -d ';' size
        read -N $size string
        idLen="${string/%;*}"
        string="${string/#+([0-9]);}"
        id="${string:0:$idLen}"
        string="${string:$idLen}"

        metadataSize="${string/%;*}"
        string="${string/#+([0-9]);}"
        metadata="${string:0:$metadataSize}"
        string="${string:$metadataSize}"

        argv=()

        while [[ "$string" == *","*":"* ]]; do
          isPTR="${string:0:1}"
          string="${string:2}"
          argLen="${string/%:*}"
          string="${string/#+([0-9]):}"
          arg="${string:0:$argLen}"
          string="${string:$argLen}"
          [[ "$isPTR" == '1' ]] && arg="$(echo -e "\x01PTR")$arg"
          argv+=( "$arg" )
        done
        fName="${id/% *}"
        tmp="$(type -t "$fName")" &> /dev/null
        if [[ "$?" != 0 || "$tmp" != "function" ]]; then
          warning "Undefined BASH callback $fName (ID: '$id')"
          continue
        fi
        $id "$1 . bbind_sendReturn $metadata" "${argv[@]}"
        ;;
      E) return ;;
      *) warning "Unknown command -- call -- '$char'"
    esac
  done
}

BASHBinding::bbind_sendReturn() {
  argsRequired 3 $#
  local fifoDir ret
  fifoDir="$($1 . bbind_fifoDir)"
  if [ ! -p "$fifoDir/$2" ]; then
    warning "Unable to return: '$fifoDir/$2' is not a FIFO"
    return
  fi
  if [[ "$3" =~ ^$'\x01PTR'[0-9]+$ ]]; then
    ret="${3/#*PTR}"
    ret="1:$ret"
  else
    ret="0:$3"
  fi
  printf "%s" "$ret" > "$fifoDir/$2"
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

  while [[ "$data" == *":"* ]]; do
    isPTR="${data/%,*}"
    data="${data/#+([0-9]),}"
    mSize="${data/%:*}"
    data="${data/#+([0-9]):}"
    out="${data:0:$mSize}"
    data="${data:$mSize}"

    [[ "$isPTR" == '1' ]] && out="$(echo -en "\x01PTR$out")"

    eval "OUT_$counter='$out'"
    (( counter++ ))
  done

  [ -e "$2" ] && rm "$2"
}
