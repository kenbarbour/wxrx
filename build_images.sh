#!/bin/sh
## Produces satellite images
##
## usage: __PROG__ [options] <wavfile> ...

rootdir=$(git rev-parse --show-toplevel)
output_prefix="wxrx-$(date +%Y%m%d%H%M)"
wavfile="pass.wav"
enhancements="ZA NO MSA MCIR therm"

if [ ! -f ${wavfile} ]; then
  exit 1
fi


for en in $enhancements; do
  wxtoimg -e ${en} $wavfile ${output_prefix}-${en}.png
done
