#!/bin/bash
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=$(basename "${prog}")
rootdir=$(dirname $(realpath $0))
source "${rootdir}/lib/utils.sh"

function usage() {
  grep '^##' "$prog" | sed -e 's/^##\s\?//' -e "s/__PROG__/$me/" 1>&2
}

# defaults
freq="137M"
duration=10
gain_flag=''
sample_rate=11025
bandwidth=40000
now=$(date +%s)
# bandwidth = 2 * (17kHz deviation + 2.4kHz tone) * doppler shift (~1.2kHz)
# wavfile is determined by options

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
      gain_flag="-g ${2}"
      log "gain set to ${2}"
      shift
      ;;

## --outfile <string>           sets the name of the output file, overrides any -noaa-** options
    '--outfile')
      wavfile=${2:-pass.wav}
      log "will write to ${wavfile}"
      shift
      ;;

## --noaa-15                    alias --freq 137620000 --outfile noaa_15-${now}.wav
    '--noaa-15')
      freq=137620000
      ${wavfile:="noaa_15-${now}.wav"}
      ;;

## --noaa-18                    alias --freq 137912500 --outfile noaa_18-${now}.wav
    '--noaa-18')
      freq=137912500
      ${wavfile:="noaa_18-${now}.wav"}
      ;;

## --noaa-19                    alias --freq 137100000 --outfile noaa_19-${now}.wav
    '--noaa-19')
      freq=137100000
      ${wavfile:="noaa_19-${now}.wav"}
      ;;

# TODO: ## --bias-t, -T                 enable hardware Bias-T power

## --monitor                    monitor recording
    '--monitor')
      monitor=1
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

function demodulate_pass() {
  timeout ${duration} rtl_fm -T -f ${freq} -M fm ${gain_flag} -s ${bandwidth} -r ${sample_rate} -E wav -E deemp -F 9 -A fast
}

function resample_pass() {
  sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${wavfile:=pass.wav}
}

function monitor_pass() {
  ( [ -z $monitor ] && cat || tee >(play -r ${sample_rate} -t raw -es -b 16 -c 1 -V1 -) )
}

log "Current timestamp: %s" ${now}
log "Listening for signal on ${freq} for ${duration} seconds (gain: ${gain})"

demodulate_pass | monitor_pass | resample_pass

# Cleanup
log "Finished writing to ${wavfile}"

# Verify that a wavfile was created
if [ ! -f ${wavfile} ]; then
  err "No output. Try the --debug flag"
  exit 1
fi

