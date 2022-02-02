#!/usr/bin/env sh
## Producess NOAA Satellite images from WAV
## 
## Usage: __PROG__ [options] wavfile
##
prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh
count=0
enhancements="MSA ZA NO MCIR therm"
tle_file="satellites.tle"

# Guesses the timestamp of a file based on the duration and mtime
# This assumes the file was finished writing at the end of a pass
# @param filename
# @output unix timestamp
function guess_timestamp() {
  wavfile=${1}
  duration=$(printf "%.0f\n" $(soxi -D ${1}))
  mtime=$(stat -c %Y ${1})
  expr ${mtime} - ${duration} + 2
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
  manifest=${prefix}-manifest.txt

  # check wavfile exists
  if [ ! -f ${wavfile} ]; then
    logerr "No such file ${wavfile}"
    exit 3
  fi
  log "Creating manifest file ${manifest}"
  echo "${wavfile}" > ${manifest}

  # quietly mkdir -p the output
  mkdir -p $(dirname ${prefix})

  ts=${timestamp:=$(guess_timestamp $wavfile)}

  # if sat and timestamp supplied, generate a map
  if [ ! -z "${satellite}" ]; then
    mapfile="${prefix}-map.png"
    # working cmd:
    # wxmap -T 'NOAA 15' -G . -H satellites.tle 1643720373 map.png
    wxmap -T "${satellite}" -G . -H "${tle_file}" -p 0 -l 0 -o ${ts} ${mapfile}
    if [ $? -gt 0 ]; then
      logerr "Error generating map"
    else
      map_flag="-m ${mapfile}"
      log "Generated map ${mapfile}"
    fi
    echo ${mapfile}
  fi

  for en in $enhancements; do
    imgfile=${prefix}-${en}.png
    wxtoimg ${map_flag:- } -e ${en} ${wavfile} ${imgfile}
    if [ $? -ne 0 ]; then
      logerr "Error generating %s with %s enhancement" "${en}" "${imgfile}"
    else
      log "Generated image ${imgfile}"
      echo "${imgfile}" >> ${manifest}
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

## --noaa-15                    Aliases for --satellite <name>
## --noaa-18
## --noaa-19
    --noaa-1[589])
        satellite="NOAA $(echo ${1} | grep -oP '[0-9]+')"
      ;;

## --timestamp <timestamp>      Unix timestamp of AOS. (default: based on duration and mtime)
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

## --satellite <name>           Satellite name. Needed to overlay a map
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
