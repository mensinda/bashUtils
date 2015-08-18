#!/bin/bash

BASHBinding::bbind_start() {
  argsRequired 1 $#
  msg1 "Starting $($1 classname)"
  [[ "$($1 . isCompiled)" != 'true' ]] && die "Not compiled!"
  local fifoDir line fIn fIndex fName className
  fifoDir="$($1 . fifoDir)"
  className="$($1 classname)"

  $($1 . libPath) "$($1 . fifoDir)" &
  $1 . bindingThread "$!"

  exec 100>"$($1 . fifoDir)/bindingCALL"
  exec 101>"$($1 . fifoDir)/shellRETURN"

  $1 . bbind_readReturn   < "$fifoDir/bindingRETURN" 3>&100 4>&101 &
  $1 . bbind_readReturnThread "$!"
  $1 . bbind_readCallback < "$fifoDir/shellCALL"     3>&100 4>&101 &
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
            call=\"\${call}1,\${#i}:\${i/#*PTR}\"
          else
            call=\"\${call}0,\${#i}:\$i\"
          fi
        done
        \$1 . bbind_sendCALL \"$fifoDir/\$id\" \"C\${#call};\$call\"
      }
    "
  done < "$fifoDir/tmp_func_def"
  rm "$fifoDir/tmp_func_def"

  $1 . isStarted     'true'
}

BASHBinding::bbind_stop() {
  argsRequired 1 $#
  [[ "$($1 . isStarted)" != 'true' ]] && return
  $1 . isStarted 'false'
  msg1 "Stopping $($1 classname) ..."

  echo 'E' 1>&100
  echo 'E' 1>&101

  # Closing pipes
  exec 100>&-
  exec 101>&-

  wait "$($1 . bindingThread)"
  wait "$($1 . bbind_readReturnThread)"
  wait "$($1 . bbind_readCallbackThread)"

  msg2 "DONE"
}
