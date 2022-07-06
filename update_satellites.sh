#!/usr/bin/env bash
## Fetch satellite TLE data
## usage: __PROG__ [<outfile>=satellites.tle]

prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh

# Print usage
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit;
fi

outfile=${1:-'satellites.tle'}

log "Updating satellite information"

curl https://www.celestrak.com/NORAD/elements/weather.txt 2>/dev/null | \
  grep 'NOAA 15\|NOAA 18\|NOAA 19' --no-group-separator -A 2 > ${outfile}

if [ $? ]; then
  log "Wrote to ${outfile}"
  exit
else
  err "Unable to fetch satellite information"
  exit 1
fi
