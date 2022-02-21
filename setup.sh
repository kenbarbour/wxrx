#!/bin/bash
## Install dependencies
##
## usage: __PROG__ [options]
##

set -o pipefail
prog="$0"
me=${HELP:-$(basename "${prog}")}
rootdir=$(dirname $(realpath $0))
tmpdir=/tmp/wxrx/setup
source "${rootdir}/lib/utils.sh"

function install_wxtoimg() {
  local url='https://static.kenbarbour.com/download/wxtoimg-linux64-2.10.11-1.tar.gz'
  local tarfile=${tmpdir}/$(basename ${url})

  mkdir -p $(dirname $tarfile)
  curl --output "${tarfile}" "${url}"
  tar xzf "${tarfile}" -C / || logerr "wxtoimg requires root to install"
  log "wxtoimg requires additional steps to install; run 'wxtoimg' manually to complete"
}

function has_wxtoimg() {
  command -v wxtoimg &>/dev/null
}

function install_predict() {
  local url='https://www.qsl.net/kd2bd/predict-2.2.7.tar.gz'
  local tarfile=${tmpdir}/$(basename ${url})

  mkdir -p $(dirname $tarfile)
  curl --output "${tarfile}" "${url}"
  # TODO untar
}

function has_predict() {
  command -v wxtoimg &>/dev/null
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

# Install wxtoimg
if ! has_wxtoimg; then
  log "Installing wxtoimg..."
  install_wxtoimg
else
  log "wxtoimg already installed"
fi

# Install predict
if [ ! has_predict ]; then
  log "Installing predict"
  install_predict
else
  log "predict already installed"
fi

# # TODO: Install rtlsdr
# if [ ! has_rtl ]; then
#   log "Installing rtlsdr drivers"
#   install_rtlsdr
# else
#   log "rtlsdr drivers already installed"
# fi
