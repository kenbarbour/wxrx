#!/bin/bash
## Schedules upcoming passes
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=${HELP:-$(basename "${prog}")}
rootdir=$(dirname $(realpath ${BASH_SOURCE}))
source "${rootdir}/lib/utils.sh"

function process_args() {
while (( "$#" ))
do
  case $1 in

## --hours <integer>
    '--hours')
      hours=${2}
      shift
      ;;

## --dir <path>                 Directory to place data (default: ./<month>/<day>)
    '--dir')
      output_path=${2}
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

# Reformat a satellite name from 'NOAA 15' to '--noaa-15'
# @param string satellite
# @output string to STDOUT
function satellite_name_flag() {
  local satellite=${1}
  echo $satellite |
  sed -e 's/\(.*\)/\L\1/' |
  sed -e 's/[[:blank:]]\+/-/g' |
  sed -e 's/^/--/'
}

function schedule_pass() {
  local time=${2}
  local duration=${3}
  local satellite=${*:4}
  local at=${1}

  ${at:-'at'} -q w -t "$(echo $time | cut -d'.' -f1)" <<EOF 2>&1 2>&1 | grep -oP '(?<=job\s)[0-9]+' >> wxrx-jobs
sleep $(echo ${time} | cut -d'.' -f2)
wxrx run $(satellite_name_flag "${satellite}") --duration ${duration} >> ./wxrx-log
EOF
}

# @param string mock for `atd`
function schedule_passes() {
  local at=${1:-'at'}

  while read -r line; do
    schedule_pass "${at}" ${line}
  done

}

function unschedule_passes() {
  # local jobfile=${1:-'.wxrx-jobs'}
  # for line in $(cat ${jobfile}); do
  #   atrm $line
  # done
  # >${jobfile}
  local jobs=$(atq -q w | cut -f1)
  if [ -n "${jobs}" ]; then
    # log "Removing atd job: %s" "$(echo $jobs)"
    atrm $(echo ${jobs})
  fi
}



# if sourced, return here. the rest of this script has side effects
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return
fi

# -- Default Values --
hours=${hours:=24}

# -- Do work below here --
process_args $@

(cd ${output_path:-.}; unschedule_passes; wxrx predict --look-ahead "${hours}" --date-format '+%Y%m%d%H%M.%S' |
schedule_passes)
