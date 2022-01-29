#!/usr/bin/env sh
## Producess NOAA Satellite images from WAV
## 
## Usage: __PROG__ [options] wavfile
##
prog="$0"
me=`basename "$prog"`
rootdir=$(git rev-parse --show-toplevel)
count=0
enhancements="ZA NO MSA MCIR therm"
tle_file="${rootdir}/satellites.tle"

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

# Creates images from a recorded pass on the filesystem
# @global output_prefix
# @global satellite
# @global timestamp
# @global tle_file
# @global enhancements
# @param wavfile path to file to create images from
# @output one line per file created
function make_images() {
  wavfile=${1}
  prefix=${output_prefix:-$(basename ${wavfile} .wav)}

  # check wavfile exists
  if [ ! -f ${wavfile} ]; then
    logerr "No such file ${wavfile}"
    exit 3
  fi

  # quietly mkdir -p the output
  mkdir -p $(dirname ${prefix})

  # if sat and timestamp supplied, generate a map
  if [ ! -z ${timestamp} ] && [ ! -z "${satellite}" ]; then
    mapfile="${prefix}-map.png"
    map_flag="-m ${mapfile}"
    wxmap -T "${satellite}" -H "${tle_file}" -p 0 -l 0 -o ${timestamp} ${mapfile}
    if [ $? ]; then
      logerr "Error generating map"
      exit 4
    fi
    echo ${mapfile}
  fi

  for en in $enhancements; do
    wxtoimg ${map_flag:- } -e ${en} ${wavfile} ${prefix}-${en}.png
    if [ $? ]; then
      logerr "Error creating image with enhancement ${en}"
      exit 5
    fi
  done
  ((count++))
}

##  Options:
while (( "$#" ));
do

## --help, -h                   Help message
  case "${1}" in
    '--help' | '-h')
      usage
      exit
      ;;

## --timestamp <timestamp>      Unix timestamp of AOS. Needed (along with --satellite) to overlay a map
    '--timestamp')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        logerr "Option ${1} must have an integer argument"
        usage
        exit 1
      fi
      timestamp=${2}
      shift
      ;;

## --satellite <name>      Satellite name. Needed (along with --timestamp) to overlay a map
    '--satellite')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      satellite=${2}
      shift
      ;;

## --output <prefix>            Prefix output with string (default based in input filename)
    '--output')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      output_prefix=${2}
      shift
      ;;

## --tle <file>                 Path to tle file (default: satellites.tle)
    '--tle')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
        usage
        exit 1
      fi
      if ! [[ "$2" =~ ^[0-9]+$ ]]; then
        logerr "Option ${1} must have an integer argument"
        usage
        exit 1
      fi
      tle_file=${2}
      if [ ! -f ${tle_file} ]; then
        logerr "Unable to locate tle file: ${tle_file}"
        exit 6
      fi
      shift
      ;;


    *)
      # if this is an unrecognized flag, log an error
      if [[ $1 == -* ]] ; then
        logerr "Unknown option %s.  If you meant to process the a file named '%s' use './%s'" ${1} ${1} ${1}
        usage
        exit 1
      fi
      make_images ${1}
      ;;
  esac
  shift
done

if [[ ${count} -lt 1 ]]; then
  logerr "No files processed.  Supply the path to one or more wav files"
  usage
  exit 1
fi

exit # normal exit
