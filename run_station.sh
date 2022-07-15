#!/usr/bin/env bash
## Handles the reception, decoding, and website generation of a single pass
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=${HELP:-$(basename "${prog}")}
rootdir=$(dirname $(realpath ${BASH_SOURCE}))
source "${rootdir}/lib/utils.sh"

# defaults
freq="137M"
duration=10
now=$(date +%s)
# bandwidth = 2 * (17kHz deviation + 2.4kHz tone) * doppler shift (~1.2kHz)
# wavfile is determined by options

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

## --satellite <name>           Satellite name (ex: noaa-15)
    '--satellite')
      satellite=${2}
      shift
      ;;

## --noaa-15                    Handle a pass of NOAA 15
    '--noaa-15')
      satellite='noaa-15'
      ;;

## --noaa-18                    Handle a pass of NOAA 18
    '--noaa-18')
      satellite='noaa-18'
      ;;

## --noaa-19                    Handle a pass of NOAA 19
    '--noaa-19')
      satellite='noaa-19'
      ;;

## --dir <path>                 Directory to place data (default: ./<month>/<day>)
    '--dir')
      output_path=${2}
      shift
      ;;

## --basename <string>          Base name to prefix files with (default: <satellite>-<timestamp>)
    '--basename')
      file_basename=${2}
      shift
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


#
# @param duration of pass in seconds
# @param name of satellite 'ex: noaa-15'
# @param path to output wavfile
# @output flags to pass to receive pass command
function receive_pass_flags() {
  local duration=${1}
  local satellite=${2}
  local outfile=${3}
  printf ' --duration %s --%s --output %s' "${duration}" "${satellite}" "${outfile}"
}

# @param wavfile path
# @param name of satellite 'ex: noaa-15'
# @param timestamp (unix)
# @param output_prefix
# @output flags to pass to build images command
function build_images_flags() {
  local audio_file=${1}
  local timestamp=${2}
  local satellite=${3}
  printf " --timestamp %s --%s %s" "${timestamp}" "${satellite}" "${audio_file}"
}

function generate_website_flags() {
  printf ""
}

# Determine a reasonable default directory to place files generated
# @param integer timestamp
# @output string
function get_default_dir() {
  local ts=${1:-$(date +%s)}
  echo "./$(date -d @${ts} +%Y\/%m)"
}

# Determine a resonable default basename for files generated
# @param string satellite name
# @param integer timestamp
# @output string basename
function get_default_basename() {
  local satellite=${1:-pass}
  local timestamp=${2:-${now}}
  echo "$(printf "%s" ${satellite} | sed s/-/_/)-${timestamp}"
}

# if sourced, return here. the rest of this script has side effects
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return
fi

# -- Do work below here --
process_args $@

# -- Default Values --
output_path=${output_path:=$(get_default_dir ${now})}
satellite=${satellite:='noaa-15'}
file_basename=${file_basename:=$(get_default_basename "${satellite}" "${now}")}
audio_file=${output_path}/${file_basename}.wav

mkdir -p ${output_path}

# Receive the pass (receive_pass.sh)
printf "audio file: %s\n" "${audio_file}"
wxrx record $(receive_pass_flags "$duration" "${satellite}" "${audio_file}")
if [[ $? != 0 ]]; then
  logerr "Errors occurred receiving signal"
  exit 10
fi

# TODO: exit if ${audio_file} does not exist
if [[ ! -r "${audio_file}" ]]; then
  logerr "Missing audio file %s.  This is likely a bug in wxrx record" "${audio_file}"
  exit 11
fi


# Decode the images
wxrx decode $(build_images_flags "${audio_file}" "${now}" "${satellite}")
if [[ $? != 0 ]]; then
  logerr "Errors occurred decoding recorded signal"
  exit 20
fi

# Generate website
wxrx web $(generate_website_flags)
