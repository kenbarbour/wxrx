#!/usr/bin/env bash
## Predict future passes
## 
## Usage: __PROG__ [options]
##
## Reports tab delimited passes in the form:
## [starttime] [duration] [satellite]
##
prog="$0"
me=${HELP:-`basename "$prog"`}
root_dir=$(dirname $(realpath $0))
source ${root_dir}/lib/utils.sh

# default values
tlefile=${tlefile:=satellites.tle}
min_duration=${min_duration:=0}
min_elevation=${min_elevation:=45}
max_aos=$(expr 86400 + $(date +%s))
date_format='+%F %T'

##  Options:
while (( "$#" ));
do

## --help, -h                   Help message
  case "${1}" in
    '--help' | '-h')
      usage
      exit
      ;;

# --bar [baz]                  Optional value
    '--bar')
      if [[ -z $2 ]] || [[ $2 == -* ]] ; then
        bar="default"
      else
        bar=$2
        shift
      fi
      ;;

## --all, -a                    Don't exclude any passes
    '--all' | '-a')
      min_duration=0
      min_elevation=0
      ;;

## --date-format <string>       Specify a date format string
    '--date-format')
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      date_format=${2}
      shift
      ;;

## --min-duration <seconds>     Minimum duration to include in report (default 0)
    '--min-duration')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      # integers only
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        logerr "Option ${1} must have an integer argument"
        usage
        exit 1
      fi
      min_duration=${2}
      shift
      ;;

## --min-elevation <degrees>    Satellite must rise above this elevation (default 45)
    '--min-elevation')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "option ${1} requires an argument"
        usage
        exit 1
      fi
      # integers only
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        logerr "option ${1} must have an integer argument"
        usage
        exit 1
      fi
      min_elevation=${2}
      shift
      ;;

## --look-ahead <hours>         Hours in advance to predict (default: 24)
    '--look-ahead')
       # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "option ${1} requires an argument"
        usage
        exit 1
      fi
      # integers only
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        logerr "option ${1} must have an integer argument"
        usage
        exit 1
      fi
      max_aos=$(expr $(expr "$2" \* 3600) + $(date +%s))
      shift
      ;;

    *)
      logerr "Unknown option %s" ${1}
      usage
      exit 1
      ;;
  esac
  shift
done

# Check `predict` command exists
if ! command -v 'predict' &> /dev/null
then
  logerr "Missing dependency 'predict'. Get it from 'https://www.qsl.net/kd2bd/predict.html'"
  exit 3
fi

# Check tle file exists
if [ ! -e ${tlefile} ]; then
  logerr "Missing satellite telemetry file ${tlefile}"
  exit 2
fi

# Produces a single line prediction
# @param satellite name (ex: 'NOAA-15')
# @param unix timestamp (default: now)
# @output writes to stdout '<aos timestamp> <duration seconds> <elevation> <sat name>'
function prediction() {
  sat_name=${1:-'NOAA-15'}
  timestamp=${2}
  pass=$(predict -t satellites.tle -p "${sat_name}" "${timestamp}")
  aos=$(printf "%s\n" "$pass" | head -n 1 | cut -d ' ' -f 1)
  los=$(printf "%s\n" "$pass" | tail -n 1 | cut -d ' ' -f 1)
  ele=$(printf "%s\n" "$pass" | awk 'BEGIN{a=0}{if ($5>0+a) a=$5} END{print a}')
  duration=$(expr ${los} - ${aos})
  printf "%s\t%s\t%s\t%s\n" "${aos}" "${duration}" "${ele}" "${sat_name}"
}

#
# Predicts all passes of a satellite until $max_aos
# satisfying max_duration and max_elevation
# @param satellite name
# @global min_duration
# @global min_elevation
# @global max_aos
# @global date_format (default '+%F %T')
# @output '<human-timestamp> <seconds duration> <sat_name>'
function predict_all() {
  sat_name=${1:-'NOAA 15'}
  last_aos=$(date +%s)
  while [ $last_aos -lt $max_aos ]; do
    pass=$(prediction "${sat_name}" "${last_aos}")
    aos=$(printf "%s" "$pass" | cut -f 1)
    duration=$(printf "%s" "$pass" | cut -f 2)
    ele=$(printf "%s" "$pass" | cut -f 3)
    starttime=$(date -d @${aos} "${date_format:-'+%F %T'}")
    last_aos=$(expr 90 + $(expr ${aos} + ${duration}))

    # if min_duration and min_elevation satisfied, print
    if [ ${min_duration:-0} -lt ${duration} ] && [ ${min_elevation:-0} -lt ${ele} ] ; then
      printf "%s\t%s\t%s\n" "${starttime}" "${duration}" "${sat_name}"
    fi
  done
}


predictions=$(for satellite in 'NOAA 15' 'NOAA 18' 'NOAA 19'; do
  predict_all "${satellite}"
done | sort)
printf "%s\n" "${predictions}"

exit # normal exit
