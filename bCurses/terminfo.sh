#!/bin/bash

__INTERNAL_boolNames=(
    'bw' 'am' 'xsb' 'xhp' 'xenl' 'eo' 'gn' 'hc' 'km' 'hs' 'in' 'da' 'db' 'mir' 'msgr' 'os' 'eslok'
    'xt' 'hz' 'ul' 'xon' 'nxon' 'mc5i' 'chts' 'nrrmc' 'npc' 'ndscr' 'ccc' 'bce' 'hls' 'xhpa' 'crxm'
    'daisy' 'xvpa' 'sam' 'cpix' 'lpix'

    'backspaces_with_bs' 'crt_no_scrolling' 'no_correctly_working_cr' 'gnu_has_meta_key'
    'linefeed_is_newline' 'has_hardware_tabs' 'return_does_clr_eol' )

__INTERNAL_numNames=(
    'cols' 'it' 'lines' 'lm' 'xmc' 'pb' 'vt' 'wsl' 'nlab' 'lh' 'lw' 'ma' 'wnum' 'colors' 'pairs'
    'ncv' 'bufsz' 'spinv' 'spinh' 'maddr' 'mjump' 'mcs' 'mls' 'npins' 'orc' 'orl' 'orhi' 'orvi'
    'cps' 'widcs' 'btns' 'bitwin' 'bitype'

    'magic_cookie_glitch_ul' 'carriage_return_delay' 'new_line_delay' 'backspace_delay'
    'horizontal_tab_delay' 'number_of_function_keys' )

__INTERNAL_strNames=(
    'cbt' 'bel' 'cr' 'csr' 'tbc' 'clear' 'el' 'ed' 'hpa' 'cmdch' 'cup' 'cud1' 'home' 'civis' 'cub1'
    'mrcup' 'cnorm' 'cuf1' 'll' 'cuu1' 'cvvis' 'dch1' 'dl1' 'dsl' 'hd' 'smacs' 'blink' 'bold' 'smcup'
    'smdc' 'dim' 'smir' 'invis' 'prot' 'rev' 'smos' 'smul' 'ech' 'rmacs' 'sgr0' 'rmcup' 'rmdc'
    'rmir' 'rmso' 'rmul' 'flash' 'ff' 'fsl' 'is1' 'is2' 'is3' 'if' 'ich1' 'il1' 'ip' 'kbs' 'ktbc'
    'kclr' 'kctab' 'kdch1' 'kdl1' 'kcud1' 'krmir' 'kel' 'ked' 'kf0' 'kf1' 'kf10' 'kf2' 'kf3' 'kf4'
    'kf5' 'kf6' 'kf7' 'kf8' 'kf9' 'khome' 'kich1' 'kil1' 'kcub1' 'kll' 'knp' 'kpp' 'kcuf1' 'kind'
    'kri' 'khts' 'kcuu1' 'rmkx' 'smkx' 'lf0' 'lf1' 'lf10' 'lf2' 'lf3' 'lf4' 'lf5' 'lf6' 'lf7' 'lf8'
    'lf9' 'smm' 'rmm' 'nel' 'pad' 'dch' 'dl' 'cud' 'ich' 'indn' 'il' 'cub' 'cuf' 'rin' 'cuu' 'pfkey'
    'pfloc' 'pfx' 'mc0' 'mc4' 'mc5' 'rep' 'rs1' 'rs2' 'rs3' 'rf' 'rc' 'vpa' 'sc' 'ind' 'ri' 'sgr'
    'hts' 'wind' 'ht' 'tsl' 'uc' 'hu' 'iprog' 'ka1' 'ka2' 'kb2' 'kc1' 'kc2' 'mc5p' 'rmp' 'acsc' 'pln'
    'kcbt' 'smxon' 'rmxon' 'smam' 'rmam' 'xonc' 'xoffc' 'enacs' 'smln' 'rmln' 'kbeg' 'kcan' 'kclo' 'kcmd'
    'kcpy' 'kcrt' 'kend' 'kent' 'kext' 'kfnd' 'khlp' 'kmrk' 'kmsg' 'kmov' 'knxt' 'kopn' 'kopt' 'kprv'
    'kprt' 'krdo' 'kref' 'krfr' 'krpl' 'krst' 'kres' 'ksav' 'kspd' 'kund' 'kBEG' 'kCAN' 'kCMD' 'kCPY'
    'kCRT' 'kDC'  'kDL'  'kslt' 'kEND' 'kEOL' 'kEXT' 'kFND' 'kHLP' 'kHOM' 'lIC'  'kLFT' 'kMSG' 'kMOV'
    'kNXT' 'kOPT' 'kPRV' 'kPRT' 'kRDO' 'kRPL' 'kRIT' 'kRES' 'kSAV' 'kSPD' 'kUND' 'rfi'  'kf11' 'kf12'
    'kf13' 'kf14' 'kf15' 'kf16' 'kf17' 'kf18' 'kf19' 'kf20' 'kf21' 'kf22' 'kf23' 'kf24' 'kf25' 'kf26'
    'kf27' 'kf28' 'kf29' 'kf30' 'kf31' 'kf32' 'kf33' 'kf34' 'kf35' 'kf36' 'kf37' 'kf38' 'kf39' 'lf40'
    'kf41' 'kf42' 'kf43' 'kf44' 'kf45' 'kf46' 'kf47' 'kf48' 'kf49' 'kf50' 'kf51' 'kf52' 'kf53' 'kf54'
    'kf55' 'kf56' 'kf57' 'kf58' 'kf59' 'kf60' 'kf61' 'kf62' 'kf63' 'el1' 'mgc' 'smgl' 'smgr' 'fln' 'sclk'
    'dclk' 'rmclk' 'cwin' 'wingo' 'hup' 'dial' 'qdial' 'tone' 'pulse' 'hook' 'pause' 'wait' 'u0' 'u1'
    'u2' 'u3' 'u4' 'u5' 'u6' 'u7' 'u8' 'u9' 'op' 'oc' 'initc' 'initp' 'scp' 'setf' 'setb' 'cpi' 'lpi'
    'chr' 'cvr' 'defc' 'swidm' 'sdrfq' 'sitm' 'slm' 'smicm' 'snlq' 'snrmq' 'sshm' 'ssubm' 'ssupm'
    'sum' 'rwidm' 'ritm' 'rlm' 'rmicm' 'rshm' 'rsubm' 'rsupm' 'rum' 'mhpa' 'mcud1' 'mcub1' 'mcuf1'
    'mvpa' 'mcuu1' 'porder' 'mcud' 'mcub' 'mcuf' 'mcuu' 'scs' 'smgb' 'smgbp' 'smglp' 'smgrp' 'smgt'
    'smgtp' 'sbim' 'scsd' 'rbim' 'rcsd' 'subcs' 'supcs' 'docr' 'zerom' 'csnm' 'kmous' 'minfo' 'reqmp'
    'getm' 'setaf' 'setab' 'pfxl' 'devt' 'csin' 's0ds' 's1ds' 's2ds' 's3ds' 'smglr' 'smgtb' 'birep'
    'binel' 'bicr' 'colornm' 'defbi' 'endbi' 'setcolor' 'slines' 'dispc' 'smpch' 'rmpch' 'smsc'
    'rmsc' 'pctrm' 'scesc' 'scesa' 'ehhlm' 'elhlm' 'elohlm' 'erhlm' 'ethlm' 'evhlm' 'sgr1' 'slength'

    'termcap_init2' 'termcap_reset' 'linefeed_if_not_lf' 'backspace_if_not_bs' 'other_non_function_keys'
    'arrow_key_map' 'acs_ulcorner' 'acs_llcorner' 'acs_urcorner' 'acs_lrcorner' 'acs_ltee' 'acs_rtee'
    'acs_btee' 'acs_ttee' 'acs_hline' 'acs_vline' 'acs_plus' 'memory_lock' 'memory_unlock' 'box_chars_1')

__INTERNAL_setUp_Terminfo_Vars() {
  local i
  for i in "${__INTERNAL_boolNames[@]}" "${__INTERNAL_numNames[@]}" "${__INTERNAL_strNames[@]}"; do
    -- $i
  done
}

class bTermInfo
  private:
    -- tiFile
    -- contentHex

    -- termName

  public:
    :: bTermInfo

    :: loadTIfile
    :: updateScreenSize

    -- setBool
    -- setNum
    -- setSTR

__INTERNAL_setUp_Terminfo_Vars

ssalc

bTermInfo::bTermInfo() {
  which tput &> /dev/null
  (( $? != 0 )) && die "tput not found; Please install ncurses"
  $1 . updateScreenSize

  local tiFiles=( "/usr/share/terminfo/${TERM:0:1}/$TERM" )
  local i

  for i in "${tiFiles[@]}"; do
    if [ -f "$i" ]; then
      $1 . tiFile "$i"
      $1 . loadTIfile
      return
    fi
  done

  die "Unable to find terminfo file for '$TERM'"
}

bTermInfo::updateScreenSize() {
  COLUMNS=$(tput cols)
  LINES=$(tput lines)
}


# static helper
bTermInfo::readBool() {
  if [[ "${contentHex:0:2}" == "00" ]]; then
    eval "$1=\"false\""
  else
    eval "$1=\"true\""
  fi
  contentHex="${contentHex:2}"
}

# static helper
bTermInfo::readShortInt() {
  local data
  data="0x${contentHex:2:2}${contentHex:0:2}"
  [[ "$data" == "0xFFFF" || "$data" == "0xffff" ]] && data="-1"
  eval "$1=\"\$((data))\""
  contentHex="${contentHex:4}"
}

# static helper
bTermInfo::hex2String() {
  local str="${!1}" data

  while [ -n "$str" ]; do
    [[ "${str:0:2}" == "00" ]] && break
    data="${data}\x${str:0:2}"
    str="${str:2}"
  done

  [ -z "$data" ] && return
  eval "$2=\$'$data'"
}

bTermInfo::loadTIfile() {
  local temp result i contentHex str setBool setNum setSTR

  contentHex="$(hexdump -ve '1/1 "%.2x"' "$($1 . tiFile)")"

  bTermInfo::readShortInt magicNum
  bTermInfo::readShortInt sizeName
  bTermInfo::readShortInt sizeBool
  bTermInfo::readShortInt numIntNum
  bTermInfo::readShortInt offsetString
  bTermInfo::readShortInt sizeString

  # read term name
  temp="${contentHex:0:$(( sizeName * 2 ))}"
  bTermInfo::hex2String temp temp
  $1 . termName "$temp"
  contentHex="${contentHex:$(( sizeName * 2 ))}"

  for i in "${__INTERNAL_boolNames[@]}"; do
    $1 . "$i" 'false'
  done

  # Parse bool section
  for (( i=0; i<sizeBool; i++ )); do
    temp="${__INTERNAL_boolNames[$i]}"
    bTermInfo::readBool result
    $1 . "$temp" "$result"
    setBool="$setBool $temp"
  done

  # Skip null byte
  if (( ($sizeName + $sizeBool) % 2 == 1 )); then
    contentHex="${contentHex:2}"
  fi

  # Parse num section
  for i in "${__INTERNAL_numNames[@]}"; do
    $1 . "$i" '-1'
  done

  for (( i=0; i<numIntNum; i++ )); do
    temp="${__INTERNAL_numNames[$i]}"
    bTermInfo::readShortInt result
    $1 . "$temp" "$result"
    setNum="$setNum $temp"
  done

  # Parse string section
  local offsets=()
  for (( i=0; i<offsetString; i++ )); do
    bTermInfo::readShortInt temp
    (( temp *= 2 ))
    offsets[$i]="$temp"
  done

  for (( i=0; i<offsetString; i++ )); do
    (( ${offsets[$i]} < 0 )) && continue
    temp="${__INTERNAL_strNames[$i]}"
    str="${contentHex:${offsets[$i]}}"
    bTermInfo::hex2String str result
    $1 . "$temp" "$result"
    setSTR="$setSTR $temp"
  done

  $1 . setBool "$setBool"
  $1 . setNum  "$setNum"
  $1 . setSTR  "$setSTR"

  return
}
