#!/usr/bin/env bash
##
## __PROG__ <command> [-h|--help] ...
prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh

# <command> is required
if [ -z "${1}" ]; then
  logerr "A command is required"
  usage
  exit 1
fi
command=${1}
command_help="${me} ${command}"

## Commands:
case "$command" in

##    help          Show this help message
  'help' | '-h' | '--help')
    usage
    exit
    ;;

##    predict       Predict future passes
  'predict')
    shift
    HELP=$command_help ${rootdir}/predict_passes.sh $@
    ;;

##    record        Demodulate and record a signal
  'record')
    shift
    HELP=$command_help ${rootdir}/record.sh $@
    ;;

##    decode        Decode images from a recorded APT signal
  'decode')
    shift
    HELP=$command_help ${rootdir}/decode.sh $@
    ;;

##    web           Generate website files from decoded manifests
  'web')
    shift
    HELP=$command_help ${rootdir}/generate_website.sh $@
    ;;

##    pass          Capture and decode a pass occuring NOW
  'pass')
    shift
    HELP=$command_help ${rootdir}/run_station.sh $@
    ;;

##    update        Update satellite telemetry
  'update')
    shift
    HELP=$command_help ${rootdir}/update_satellites.sh $@
    ;;

##    schedule      Schedule a future pass with `atd`
  'schedule')
    shift
    HELP=$command_help ${rootdir}/schedule.sh $@
    ;;

  '*')
    logerr "Unrecognized command ${1}"
    usage
    exit 1

esac
