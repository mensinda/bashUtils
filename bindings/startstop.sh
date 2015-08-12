#!/bin/bash

BASHBinding::bbind_start() {
  argsRequired 1 $#
  msg1 "Starting $($1 classname)"
  [[ "$($1 . isCompiled)" != 'true' ]] && die "Not compiled!"
  local fifoDir line IN className
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
    IN="${line/#*:}"
    IN="${IN/%,*}"
    (( IN++ ))
    eval "
      ${className}::${line/%:*}() {
        argsRequired $IN \$#
        msg1 \"TODO: Implement calling functions '${line/%:*}'\"
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
