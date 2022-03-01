#!/bin/bash
## Install dependencies
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=${HELP:-$(basename "${prog}")}
rootdir=$(dirname $(realpath ${BASH_SOURCE[0]}))
tmpdir=/tmp/wxrx/setup
source "${rootdir}/lib/utils.sh"

# Download and install wxtoimg and related utilities
# @param install path (default ~/.local/)
# @param path to temporary directory for the downloaded tarball
function install_wxtoimg() {
  local url=${1:-'https://static.kenbarbour.com/download/wxtoimg-linux64-2.10.11-1.tar.gz'}

  install_from_targz "${url}" ${@:2}
  log "wxtoimg requires additional steps to install; run 'wxtoimg' manually to complete"
  # TODO: fix ./usr/bin/xwxtoimg symlink -> ./usr/bin/wxtoimg
}


function has_wxtoimg() {
  command -v wxtoimg &>/dev/null
}

function install_predict() {
  local url='https://www.qsl.net/kd2bd/predict-2.2.7.tar.gz'
  local installPath=${2:-${tmpdir}/predict}

  install_from_targz "${url}" "${installPath}" ${@:3}

  # TODO: build steps are needed
  log "predict requires additional steps to install; run 'predict' manually to complete"
}

function has_predict() {
  command -v predict &>/dev/null
}

# Download tarfile and install
# @param url
# @param install path (default ~/.local/)
# @param temporary filename for the downloaded tarball (default based on ${tmpdir} and filename)
function install_from_targz() {
  local url=${1}
  local tarfile=${3:-$tmpdir/$(basename ${url})}
  local installPath=${2:-~/.local/}

  mkdir -p $(dirname $tarfile)
  mkdir -p ${installPath}
  curl --silent --output "${tarfile}" "${url}"
  tar xzf "${tarfile}" -C "${installPath}"
}

function process_args() {
  while (( "$#" ))
  do
    case $1 in

  ## --help, -h
      '--help' | '-h')
        usage
        exit
        ;;

      *)
        err "Unknown argument %s" ${1}
        exit 1
        ;;

    esac
    shift
  done
}



# if sourced, return here. the rest of this script has side effects
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  return
fi
# -- Do work below here --
process_args $@

log "Checking for dependencies"
errorStatus=0

# Install wxtoimg
if ! has_wxtoimg; then
  log "Installing wxtoimg..."
  install_wxtoimg
  rtrn=$?
  errorStatus=$(expr $errorStatus + $rtrn)
else
  log "wxtoimg already installed"
fi

# Install predict
if [ ! has_predict ]; then
  log "Installing predict"
  install_predict
  rtrn=$?
  errorStatus=$(expr $errorStatus + $rtrn)
else
  log "predict already installed"
fi

# Finish up
if [ -z errorStatus ]; then
  log "Setup complete."
else
  logerr "Setup did not complete successfully.  See above errors for more details"
fi

exit $errorStatus
