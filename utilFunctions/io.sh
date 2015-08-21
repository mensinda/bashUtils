#!/bin/bash

ESC_CLEAR="\x1b[2K\x1b[0G"

msg1()    { echo -e "${ESC_CLEAR}\x1b[1;32m==>\x1b[1;37m $*\x1b[0m";               }
msg2()    { echo -e "${ESC_CLEAR}   \x1b[1;34m--\x1b[1;37m $*\x1b[0m";             }
msg3()    { echo -e "${ESC_CLEAR}     \x1b[1;34m--\x1b[1;37m $*\x1b[0m";           }
msg4()    { echo -e "${ESC_CLEAR}       \x1b[1;34m--\x1b[1;37m $*\x1b[0m";         }
found()   { echo -e "${ESC_CLEAR} \x1b[1;33m--> \x1b[1;37mFound $*\x1b[0m";        }
found2()  { echo -e "${ESC_CLEAR}    \x1b[1;33m--> \x1b[1;37mFound $*\x1b[0m";     }
found3()  { echo -e "${ESC_CLEAR}      \x1b[1;33m--> \x1b[1;37mFound $*\x1b[0m";   }
error()   { echo -e "${ESC_CLEAR}\x1b[1;31m==> ERROR:\x1b[1;37m $*\x1b[0m"   1>&2; }
warning() { echo -e "${ESC_CLEAR}\x1b[1;33m==> WARNING:\x1b[1;37m $*\x1b[0m" 1>&2; }

ask() {
  argsRequired 3 $#
  echo -e  "${ESC_CLEAR}\x1b[1;35m==> \x1b[1;37m$1 \x1b[1;33m[\x1b[1;37m${2}\x1b[1;33m]\x1b[0m"
  echo -en "${ESC_CLEAR}   \x1b[1;36m--\x1b[0m "
  read "$3"
  if [ -z "${!3}" ]; then
    eval "${3}=\"$2\""
    echo -en '\x1b[1A\x1b[2K' # Curser up and clear line
    msg2 "Using default '$2'"
  fi
}

printNumChar() {
  argsRequired 2 $#
  (( $1 == 0 )) && return
  local s
  s="$(printf "%-${1}s" "$2")"
  echo -n "${s// /$2}"
}
