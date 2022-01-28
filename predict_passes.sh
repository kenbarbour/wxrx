#!/usr/bin/env sh
## Predict future passes
## 
## Usage: __PROG__ [options]
##
## Reports passes in the form:
## [starttime] [duration] [frequency]
##
prog="$0"
me=`basename "$prog"`

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

# default values
tlefile=${tlefile:=satellites.tle}
min_duration=${min_duration:=0}
min_elevation=${min_elevation:=45}

##  Options:
while (( "$#" ));
do

## --help, -h                   Help message
  case "${1}" in
    '--help' | '-h')
      usage
      exit
      ;;

# --foo                        Simple switch
    '--foo')
      foo=1
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

## --min-elevation <degrees>    Minimum elevation to include in report (default 45)
    '--min-elevation')
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
      min_elevation=${2}
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

function prediction() {
  pass=$(predict -t satellites.tle -p "${1}")
  aos=$(printf "%s\n" "$pass" | head -n 1 | cut -d ' ' -f 1)
  los=$(printf "%s\n" "$pass" | tail -n 1 | cut -d ' ' -f 1)
  ele=$(printf "%s\n" "$pass" | awk 'BEGIN{a=0}{if ($5>0+a) a=$5} END{print a}')
  duration=$(expr ${los} - ${aos})
  starttime=$(date -d @${aos} '+%F %T')
  if [ $duration -lt ${min_duration:-0} ]; then
    return
  fi
  if [ $ele -lt ${min_elevation:-0} ]; then
    return
  fi

  printf "%s\t%s\t%s\t%s\n" "${starttime}" "${duration}" "${ele}" "${1}"
}

predictions=$(for satellite in 'NOAA 15' 'NOAA 18' 'NOAA 19'; do
  prediction "${satellite}"
done | sort)

printf "%s\n" "${predictions}"

exit # normal exit
