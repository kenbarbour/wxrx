#!/bin/sh
##
## __PROG__ <command> [-h|--help] ...
prog="$0"
me=`basename "$prog"`
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh

# Lines starting with '##' are intended for usage documentation
function usage() {
  grep '^##' "$prog" | sed -e 's/^##\s\?//' -e "s/__PROG__/$me/" 1>&2
}

# Like printf, but prints to stderr with prettier formatting if TTY
function logerr() {
  if [ -t 2 ]; then
    printf "$(tput setaf 1)ERROR$(tput sgr0) ${1}\n" ${@:2} 1>&2
  else
    printf "${1}\n" ${@:2} 1>&2
  fi
}

# <command> is required
if [ -z "${1}" ]; then
  logerr "A command is required"
  usage
  exit 1
fi
command=${1}

## Commands:
case "${1}" in

##    help          Show this help message
  'help' | '-h' | '--help')
    usage
    exit
    ;;

##    predict       Predict future passes
  'predict')
    shift
    ${rootdir}/predict_passes.sh $@
    ;;

##    record        Demodulate and record a signal
  'record')
    shift
    ${rootdir}/receive_pass.sh $@
    ;;

##    decode        Decode images from a recorded APT signal
  'decode')
    shift
    ${rootdir}/build_images.sh $@
    ;;

##    pass          Capture and decode a pass occuring NOW
  'pass')
    printf "TODO\n"
    ;;

##    update        Update satellite telemetry
  'update')
    shift
    ${rootdir}/update_satellites.sh $@
    ;;
##    schedule      Schedule a future pass with `atd`
  'schedule')
    printf "TODO\n"
    ;;

  '*')
    logerr "Unrecognized command ${1}"
    usage
    exit 1

esac
