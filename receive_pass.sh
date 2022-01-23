#!/bin/sh
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

set -uo pipefail
prog="$0"
me=$(basename "${prog}")
rootdir=$(git rev-parse --show-toplevel)
source "${rootdir}/lib/utils.sh"

function usage() {
  grep '^##' "$prog" | sed -e 's/^##\s\?//' -e "s/__PROG__/$me/" 1>&2
}

# defaults
freq="137M"
duration=10
gain=40
wavfile="pass.wav"
debug_out="/dev/null"

while (( "$#" ))
do
  case $1 in

## --freq <frequency>           (default: 137M)
    '--freq')
      freq=${2}
      log "frequency set to ${freq}"
      shift
      ;;

## --duration <seconds>         (default: 900)
    '--duration')
      duration=${2}
      log "duration set to ${duration}"
      shift
      ;;

## --gain <integer>             (default: auto)
    '--gain')
      gain=${2}
      log "gain set to ${gain}"
      shift
      ;;

## --outfile <string>           (default: pass.wav)
    '--outfile')
      wavfile=${2:-pass.wav}
      log "will write to ${wavfile}"
      shift
      ;;

## --debug                      (default: wxrx.log)
    '--log')
      debug_out="2"
      ;;

## --help, -h
    '--help' | '-h')
      usage
      exit
      ;;

    *)
      err "Unknown argument %s" ${1}
      exit 1
      ;;

  esac
  shift
done

# wxtoimg needs this specific sample rate
sample_rate="22050"

# TODO Verify freq and duration


log "Listening for signal on ${freq} for ${duration} seconds (gain: ${gain})"
timeout ${duration} rtl_fm -T -f ${freq} -M fm -g ${gain} -s 48000 -r ${sample_rate} -F 9 -A fast  | sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${wavfile}
if [ -z "$?" ]; then
  log "Exit status: %d, try adding --debug flag" $?
fi
log "Finished writing to ${wavfile}"

# Verify that a wavfile was created
if [ ! -f ${wavfile} ]; then
  err "No output. Try the --debug flag"
  exit 1
fi


