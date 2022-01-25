#!/bin/sh
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

set -o pipefail
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

## --noaa-15                    alias for --freq 13762000
    '--noaa-15')
      freq=137620000
      ;;

## --noaa-18                    alias for --freq 137912500
    '--noaa-18')
      freq=137912500
      ;;

## --noaa-19                    alias for --freq 137100000
    '--noaa-19')
      freq=137100000
      ;;

# TODO: ## --bias-t, -T                 enable hardware Bias-T power

## --monitor                    monitor recording
    '--monitor')
      monitor=1
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
sample_rate="11025"

# TODO Verify freq and duration

function demodulate_pass() {
  timeout ${duration} rtl_fm -T -f ${freq} -M fm -g ${gain} -s 48000 -r ${sample_rate} -F 9 -A fast
}

function resample_pass() {
  sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${wavfile}
}

function monitor_pass() {
  ( [ -z $monitor ] && cat || tee >(play -r ${sample_rate} -t raw -es -b 16 -c 1 -V1 -) )
}

log "Listening for signal on ${freq} for ${duration} seconds (gain: ${gain})"

demodulate_pass | monitor_pass | resample_pass

# Cleanup
log "Finished writing to ${wavfile}"

# Verify that a wavfile was created
if [ ! -f ${wavfile} ]; then
  err "No output. Try the --debug flag"
  exit 1
fi

