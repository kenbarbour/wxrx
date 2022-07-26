#!/usr/bin/env bash
## Producess NOAA Satellite images from WAV
## 
## Usage: __PROG__ [options] wavfile
##
## Files are created as siblings of the wavfile
##
prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh
count=0
enhancements="MSA MSA-PRECIP MCIR MCIR-PRECIP therm ZA NO pristine"
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

# @param infile
# @param outfile
function make_spectrogram() {
  sox ${1} -n spectrogram -o ${2}
}

#
# @param string satellite name
# @param path to tle file
# @param integer timestamp
# @param path to output map file
# @side-effect creates PNG map file
function make_mapfile() {
  local satellite=${1}
  local tle=${2}
  local timestamp=${3}
  local mapfile=${4}

  wxmap -T "${satellite}" -G . -H "${tle_file}" -p 0 -l 0 -o ${ts} ${mapfile} ||
  wxmap -T "${satellite}" -G . -H "${tle_file}" -p 0 -l 0 -o $(expr ${ts} + 4) ${mapfile} ||
  wxmap -T "${satellite}" -G . -H "${tle_file}" -p 0 -l 0 -o $(expr ${ts} + 8) ${mapfile}
  
}

function make_images() {
  local wavfile=${1}
  local prefix="$(dirname ${wavfile})/$(basename ${wavfile} .wav)"
  local manifest=${prefix}-manifest.txt

  # check wavfile exists
  if [ ! -f ${wavfile} ]; then
    logerr "No such file ${wavfile}"
    exit 3
  fi
  log "Creating manifest file ${manifest}"
  echo "$(basename $wavfile)" > ${manifest}

  # quietly mkdir -p the output
  mkdir -p $(dirname ${prefix})

  ts=${timestamp:=$(guess_timestamp $wavfile)}

  # if sat and timestamp supplied, generate a map
  mapfile="${prefix}-map.png"
  if [ ! -z "${satellite}" ]; then
    make_mapfile "${satellite}" "${tle_file}" "${ts}" "${mapfile}" || logerr "Error generating map"
  fi
  if [ -f $mapfile ]; then
      log "Using map file ${mapfile}"
      map_flag="-m ${mapfile}"
  fi

  for en in $enhancements; do
    imgfile=${prefix}-${en}.png
    wxtoimg ${map_flag:- } -e ${en} ${wavfile} ${imgfile}
    if [ $? -ne 0 ]; then
      logwarn "Non-zero status from wxtoimg creating ${imgfile}" "${en}" "${imgfile}"
    else 
      log "Generated image ${imgfile}"
    fi

    if [ -f ${imgfile} ]; then
      log "Adding file to manifest: ${imgfile}"
      echo "$(basename $imgfile)" >> ${manifest}
    fi
  done

  # create a spectrogram
  local spectrogram=${prefix}-spectrogram.png
  make_spectrogram ${wavfile} ${spectrogram} && echo "$(basename ${spectrogram})" >> ${manifest} && \
    log "Adding spectrogram" || logerr "Unable to generate a spectrogram"
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

# ## --output <prefix>            Prefix output with string (default based in input filename)
#    '--output')
#      # check that $2 exists and is not another flag
#      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
#        logerr "Option ${1} requires an argument"
#        usage
#        exit 1
#      fi
#      output_prefix=${2}
#      shift
#      ;;

## --tle <file>                 Path to tle file (default: satellites.tle)
    '--tle')
      # check that $2 exists and is not another flag
      if [[ $# -lt 2 ]] || [[ $2 == -* ]] ; then
        logerr "Option ${1} requires an argument"
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
