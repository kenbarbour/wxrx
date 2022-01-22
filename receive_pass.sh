#!/bin/sh
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

rootdir=$(git rev-parse --show-toplevel)
source "${rootdir}/lib/utils.sh"

## --freq <frequency>           (default: 137M)
freq="137M"

## --duration <seconds>         (default: 900)
duration=10

## --gain <integer>             (default: auto)
gain=45

## --outfile-prefix <string>    (default: wxrx-out)
outfile_prefix="wxrx-out"
wavfile="${outfile_prefix}.wav"

## --debug
debug_out="/dev/null"

# wxtoimg needs this specific sample rate
sample_rate="11025"

# TODO Verify freq and duration

err "Test"

timeout ${duration} rtl_fm -f ${freq} -M fm -g ${gain} -s ${sample_rate} 2>>${debug_out} | sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${wavfile} 

# Verify that a wavfile was created
if [ ! -f ${wavfile} ]; then
  err "No output. Try the --debug flag"
  exit 1
fi


