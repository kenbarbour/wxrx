#!/usr/bin/bash
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../schedule.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

printf "WARNING! The unit under test may use atd.  Check your atd queues.\n"

setUp() {
  cd "${SHUNIT_TMPDIR}"
  cp ${fixture_dir}/satellites.tle ${SHUNIT_TMPDIR}
  stdoutF="${SHUNIT_TMPDIR}/stdout"
  stderrF="${SHUNIT_TMPDIR}/stderr"
  >"${stdoutF}"
  >"${stderrF}"
}

mock_i=1
mock_at() {
  cat > ${SHUNIT_TMPDIR}/at-input
  printf "job %s at Foo Bar\n" "${mock_i}"
  echo "FOO!" 1>&2
  mock_i=`expr ${mock_i} + 1`
}

test_satellite_name_flag() {
  source ${unit}

  assertSame "--noaa-15" "`satellite_name_flag 'NOAA 15'`"
  assertSame "--noaa-16" "`satellite_name_flag 'NOAA 16'`"
  assertSame "--noaa-19" "`satellite_name_flag 'NOAA 19'`"
}

test_schedule_pass() {
  source ${unit}

  schedule_pass 'mock_at' '202207052000.05' '1234' 'NOAA-17' >${stdoutF} 2>${stderrF}
  assertTrue "unexpected error status" $?
  assertNull "unexpected error output" "`cat ${stderrF}`"
  assertNull "unexpected stdout" "`cat ${stdoutF}`"
  assertNotNull "no input to at" "`cat ${SHUNIT_TMPDIR}/at-input`"
  cat <<EOF >expected
sleep 05
wxrx run --noaa-17 --duration 1234 >> ./wxrx-log
EOF

  assertSame "`cat expected`" "`cat ${SHUNIT_TMPDIR}/at-input`"

}

test_schedule_passes() {
  source ${unit}

  schedule_passes 'mock_at' <<EOF > "${stdoutF}" 2>"${stderrF}"
202207052019.43	917	NOAA 15
202207052249.35	946	NOAA 18
202207060837.35	904	NOAA 15
202207060936.43	932	NOAA 19
EOF
  assertTrue "unexpected error status" $?
  assertNull "unexpected error output" "`cat ${stderrF}`"
  cat ${stderrF}
  cat ${stdoutF}
}


. shunit2
