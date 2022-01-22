#!/bin/sh

## usage: __PROG__ <outfile>

outfile=${1:-'satellites.tle'}


curl https://www.celestrak.com/NORAD/elements/weather.txt 2>/dev/null | \
  grep 'NOAA 15\|NOAA 18\|NOAA 19' --no-group-separator -A 2 > ${outfile}
