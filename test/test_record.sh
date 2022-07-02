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

test_record() {
  device_is_connected || startSkipping

  outputPath="${SHUNIT_TMPDIR}/record-test/test.wav"
  mkdir -p "$(dirname ${outputPath})"

  ${unit} --duration 1 --output "${outputPath}" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected a success exit status" $rtrn

  # rtl_fm produces error output always
  # assertNull "unexpected error output" "`cat ${stderrF}`"
  

  fileSize=$(wc -c <"${outputPath}")
  assertTrue "missing output file" "[ -r ${outputPath} ]"
  assertTrue "expected a larger wav file" "[ ${fileSize} -gt 5000 ]"
}

test_invalid_option() {
  ${unit} --this-is-not-an-option >${stdoutF} 2>${stderrF}
  rtrn=$?

  assertFalse "expected an error status" $rtrn
  assertNotNull "expected error output" "$(cat ${stderrF})"
}

setUp() {
  stdoutF="${SHUNIT_TMPDIR}/stdout"
  stderrF="${SHUNIT_TMPDIR}/stderr"
  >"${stdoutF}"
  >"${stderrF}"
}

. shunit2
