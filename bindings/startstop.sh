#!/bin/bash

BASHBinding::bbind_start() {
  argsRequired 1 $#
  [[ "$($1 . bbind_isCompiled)" != 'true' ]] && die "Not compiled!"
  local fifoDir line fIn fIndex fName className
  fifoDir="$($1 . bbind_fifoDir)"
  className="$($1 classname)"

  if [[ "$($1 . bbind_option_useGDB)" == 'true' ]]; then
    programRequired 'gdb'
    gdb -q -ex run -ex bt full --args "$($1 . bbind_execPath)" "$($1 . bbind_fifoDir)" &
  else
    $($1 . bbind_execPath) "$($1 . bbind_fifoDir)" &
  fi
  $1 . bbind_bindingThread "$!"

  exec 100>"$fifoDir/bindingCALL"

  $1 . bbind_readCallback < "$fifoDir/shellCALL" 4>&100 &
  $1 . bbind_readCallbackThread "$!"

  FIFOwait "$fifoDir/wait_init_FIFO"

  [ ! -f "$fifoDir/tmp_func_def" ] && die "Unable to find temporary function definition file"

  while read line; do
    fIn="${line/#*:}"
    fIn="${fIn/%,*}"
    fName="${line/%#*}"
    fIndex="${line/%:*}"
    fIndex="${fIndex/#*#}"
    (( fIn++ ))
    eval "
      ${className}::$fName() {
        argsRequired $fIn \$#
        local id call i
        id=\"\$(cat /dev/urandom | tr -dc '[:alnum:]' | fold -w 16 | head -n 1)\"
        mkfifo \"$fifoDir/\$id\"
        call=\"${fIndex}|\${#id};\$id\"
        for i in \"\${@:2}\"; do
          if [[ \"\$i\" =~ ^$'\x01PTR'[0-9]+$ ]]; then
            i=\"\${i/#*PTR}\"
            call=\"\${call}1,\${#i}:\$i\"
          else
            call=\"\${call}0,\${#i}:\$i\"
          fi
        done
        \$1 . bbind_sendCALL \"$fifoDir/\$id\" \"C\${#call};\$call\"
      }
    "
  done < "$fifoDir/tmp_func_def"
  rm "$fifoDir/tmp_func_def"

  $1 . bbind_isStarted     'true'
}

BASHBinding::bbind_stop() {
  argsRequired 1 $#
  [[ "$($1 . bbind_isStarted)" != 'true' ]] && return
  $1 . bbind_isStarted 'false'

  echo 'E' 1>&100

  # Closing pipes
  exec 100>&-

  wait "$($1 . bbind_bindingThread)"
  wait "$($1 . bbind_readCallbackThread)"
}
