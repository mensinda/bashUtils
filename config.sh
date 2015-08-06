#!/bin/bash

declare -A CONFIG
declare -a __INTERNAL_CONFIG_ENTRY_NAMES_LIST__

addToConfig() {
  argsRequired 3 $#
  local temp
  temp="${1/=/}"
  if [[ "$temp" != "$1" ]]; then
    die "Config names must not contain '='"
  fi

  __INTERNAL_CONFIG_ENTRY_NAMES_LIST__+=("$1")
  [ -z "${CONFIG["$1"]}" ] && CONFIG["$1"]="$2"
  CONFIG["${1}_DEF"]="$2"
  CONFIG["${1}_DESC"]="$3"
}

parseConfigFile() {
  argsRequired 1 $#
  fileRequired "$1" "require"

  local LINE
  while read LINE; do
    LINE="${LINE/\#*/}"   # Remove comments
    LINE="${LINE/%*( )/}" # Remove ' ' at the end of line ( Needs shopt extglob on )

    if [ -z "$LINE" ]; then
        continue
    fi

    local VALUE="${LINE/#*:*( )/}" # Needs shopt extglob on
    local ENTRY="${LINE/%:*/}"
    CONFIG["$ENTRY"]="$VALUE"
  done < "$1"
}

generateConfigFile() {
  argsRequired 1 $#
  for i in "${__INTERNAL_CONFIG_ENTRY_NAMES_LIST__[@]}"; do
    echo "# ${CONFIG["${i}_DESC"]}"
    if [[ "${CONFIG["$i"]}" ==  "${CONFIG["${i}_DEF"]}" ]]; then
      echo "# ${i}: ${CONFIG["$i"]}"
    else
      echo "${i}: ${CONFIG["$i"]}"
    fi
    echo ""
  done > "$1"
}
