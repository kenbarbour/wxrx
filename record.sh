#!/bin/bash
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=${HELP:-$(basename "${prog}")}
rootdir=$(dirname $(realpath $0))
source "${rootdir}/lib/utils.sh"

# defaults
freq="137M"
duration=10
gain_flag=''
sample_rate=11025
bandwidth=40000
now=$(date +%s)
output_file=./pass.wav
# bandwidth = 2 * (17kHz deviation + 2.4kHz tone) * doppler shift (~1.2kHz)
# wavfile is determined by options
# DEPRECATED
outdir=.
outfile=pass.wav

function process_args() {
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

#  --output|-o <file>       name/path of the output file or directory
    '--output' | '-o')
      output_file=${2}
      shift
      ;;

## --noaa-15                    alias --freq 137620000
    '--noaa-15')
      freq=137620000
      ;;

## --noaa-18                    alias --freq 137912500
    '--noaa-18')
      freq=137912500
      ;;

## --noaa-19                    alias --freq 137100000
    '--noaa-19')
      freq=137100000
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
      logerr "Unknown argument %s" ${1}
      exit 1
      ;;

  esac
  shift
done
}

function demodulate_pass() {
  timeout ${duration} rtl_fm -T -f ${freq} -M fm ${gain_flag} -s ${bandwidth} -r ${sample_rate} -E wav -E deemp -F 9 -A fast
}

function resample_pass() {
  local $output
  sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${output_file:-'./wxrx.wav'}
}

function monitor_pass() {
  ( [ -z $monitor ] && cat || tee >(play -r ${sample_rate} -t raw -es -b 16 -c 1 -V1 -) )
}

# If sourced, return now
if [ "${0}" != "${BASH_SOURCE[0]}" ]; then
  return
fi

# -- Do work below here --
process_args $@

log "Current timestamp: %s" ${now}
log "Listening for signal on ${freq} for ${duration} seconds (gain: ${gain})"

demodulate_pass | monitor_pass | resample_pass

# Cleanup
log "Finished writing to ${output_file}"

# Verify that a wavfile was created
if [ ! -f ${output_file} ]; then
  logerr "No output. Try the --debug flag"
  exit 1
fi

