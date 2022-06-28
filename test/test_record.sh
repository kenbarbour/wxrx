#!/usr/bin/bash
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../record.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

##
# Tests is a rtl_sdr is connected
# @return 0 if rtl_sdr is found
device_is_connected() {
  lsusb | grep RTL2838 > /dev/null
}

test_demodulate_pass() {

  # RTL_SDR is required, otherwise skip this test
  device_is_connected || startSkipping

  echo "TODO: test demodulate_pass"

}

test_resample_pass() {
  echo "TODO: test resample_pass"
}

test_monitor_pass() {
  echo "TODO: test monitor_pass"
}

. shunit2
