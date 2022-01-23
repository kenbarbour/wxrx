#!/bin/sh
## Receives a pass of a NOAA Satellite
##
## usage: __PROG__ [options]
##

set -uo pipefail
rootdir=$(git rev-parse --show-toplevel)
source "${rootdir}/lib/utils.sh"

## --freq <frequency>           (default: 137M)
freq="162450000"

## --duration <seconds>         (default: 900)
duration=10

## --gain <integer>             (default: auto)
gain=40

## --outfile-prefix <string>    (default: wxrx-out)
outfile_prefix="pass"
wavfile="${outfile_prefix}.wav"

## --debug
debug_out="wxrx.log"

# wxtoimg needs this specific sample rate
sample_rate="22050"

# TODO Verify freq and duration


log "Listening for signal on ${freq} for ${duration} seconds (gain: ${gain})"
timeout ${duration} rtl_fm -T -f ${freq} -M fm -g ${gain} -s 48000 -r ${sample_rate} -F 9 -A fast 2>>${debug_out} | sox -r ${sample_rate} -t raw -e s -b 16 -c 1 -V1 - ${wavfile}
log "Exit status: %d" $?
log "Finished writing to ${wavfile}"

# Verify that a wavfile was created
if [ ! -f ${wavfile} ]; then
  err "No output. Try the --debug flag"
  exit 1
fi


