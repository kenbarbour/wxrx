#!/usr/bin/bash
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../run_station.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

##
# Tests is a rtl_sdr is connected
# @return 0 if rtl_sdr is found
device_is_connected() {
  lsusb | grep RTL2838 > /dev/null
}

# test_helptext() {
#   timeout --foreground 1 ${unit} --help >"${stdoutF}" 2>"${stderr}"
# 
#   assertTrue "unexpected error status" ${rtrn}
#   assertNotNull "missing helptext" "`cat ${stdoutF}`"
#   assertNotNull "missing usage" "`grep 'usage:' ${stdoutF}`"
#   assertNull "unexpected STDERR" "`cat ${stderrF}`"
# }

test_get_default_dir() {
  source ${unit}

  get_default_dir >${stdoutF} 2>${stderrF}
  assertTrue "unexpected error status with no args" $?
  assertNull "unexpected error output with no args" "`cat ${stderrF}`"
  assertNotNull "unexpected empty output with no args" "`cat ${stdoutF}`"

  get_default_dir 1656770769 >${stdoutF} 2>${stderrF}
  assertTrue "unexpected error status with args" $?
  assertNull "unexpected error output with args" "`cat ${stderrF}`"
  assertSame "./2022/07" "`cat ${stdoutF}`"
}

test_get_default_basename() {
  source ${unit}

  get_default_basename >${stdoutF} 2>${stderrF}
  assertTrue "unexpected error status with no args" $?
  cat ${stderrF}
  assertNull "unexpected error output with no args" "`cat ${stderrF}`"
  assertNotNull "unexpected empty output with no args" "`cat ${stdoutF}`"

  get_default_basename 'noaa-15' 12341234 >${stdoutF} 2>${stderrF}
  assertTrue "unexpected error status with args" $?
  assertNull "unexpected error output with args" "`cat ${stderrF}`"
  assertSame "noaa_15-12341234" "`cat ${stdoutF}`"
}

test_run_station() {
  device_is_connected || startSkipping

  outputPath="${SHUNIT_TMPDIR}/record-test/cwd/test.wav"
  export WXRX_WEB_PUBDIR="${SHUNIT_TMPDIR}/record-test/public"
  mkdir -p "$(dirname ${outputPath})"
  mkdir -p "${WXRX_WEB_PUBDIR}"
  cd $(dirname $outputPath)

  ${unit} --duration 1 #>${stdoutF} 2>${stderrF}
  rtrn=$?
  cat ${stdoutF}
  if [ -nz $rtrna ]; then
    cat ${stderrF}
  fi
  assertTrue "expected a success exit status" $rtrn

  tree ..

}

setUp() {
  stdoutF="${SHUNIT_TMPDIR}/stdout"
  stderrF="${SHUNIT_TMPDIR}/stderr"
  >"${stdoutF}"
  >"${stderrF}"
}

. shunit2
