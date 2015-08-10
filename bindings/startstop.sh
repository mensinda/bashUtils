#!/bin/bash

BASHBinding::start() {
  argsRequired 1 $#
  msg1 "Starting"
  [[ "$($1 . isCompiled)" != 'true' ]] && die "Not compiled!"
  $($1 . libPath) "$($1 . fifoDir)" &
  $1 . bindingThread "$!"
  $1 . isStarted     'true'
}

BASHBinding::stop() {
  argsRequired 1 $#
  msg1 "Stopping"
  [[ "$($1 . isStarted)" != 'true' ]] && return
  wait "$($1 . bindingThread)"
  $1 . isStarted 'false'
}
