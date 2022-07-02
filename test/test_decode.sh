#!/usr/bin/bash
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../decode.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

setUp() {
  stdoutF="${SHUNIT_TMPDIR}/stdout"
  stderrF="${SHUNIT_TMPDIR}/stderr"
  >"${stdoutF}"
  >"${stderrF}"
}

test_decode_wav_with_map() {
  mkdir -p ${SHUNIT_TMPDIR}/data
  cd ${SHUNIT_TMPDIR}
  cp ${fixture_dir}/$(basename $me .sh)/noaa_15-1643760991.wav ${SHUNIT_TMPDIR}/data/pass.wav
  ${unit} --satellite noaa-15 --timestamp 1643760991 ${SHUNIT_TMPDIR}/data/pass.wav >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "unexpected error status" $rtrn

  # expect files to exist
  assertTrue "expected manifest" "[ -r ./data/pass-manifest.txt ]"
  assertTrue "expected MCIR"     "[ -r ./data/pass-MCIR.png ]"
  assertTrue "expected MSA"      "[ -r ./data/pass-MSA.png ]"
  assertTrue "expected PRECIP"   "[ -r ./data/pass-MSA-PRECIP.png ]"
  assertTrue "expected NO"       "[ -r ./data/pass-NO.png ]"
  assertTrue "expected therm"    "[ -r ./data/pass-therm.png ]"
  assertTrue "expected ZA"       "[ -r ./data/pass-ZA.png ]"
  assertTrue "expected map"      "[ -r ./data/pass-map.png ]"

  assertNotNull "expected manifest to contain MCIR image" \
    "`grep -E '^pass-MCIR\.png$' ./data/pass-manifest.txt`"
  assertNotNull "expected manifest to contain MSA image" \
    "`grep -E '^pass-MSA.png$' ./data/pass-manifest.txt`"
  assertNull "unexpected map in manifest" \
    "`grep -E '^pass-map.png$' ./data/pass-manifest.txt`"
}

test_decode_without_map() {
  mkdir -p ${SHUNIT_TMPDIR}/foo/bar
  cd ${SHUNIT_TMPDIR}
  cp ${fixture_dir}/$(basename $me .sh)/noaa_15-1643760991.wav ${SHUNIT_TMPDIR}/foo/bar/pass.wav
  ${unit} ${SHUNIT_TMPDIR}/foo/bar/pass.wav >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "unexpected error status" $rtrn

  assertFalse "unexpected map" "[ -r ./foo/bar/pass-map.png ]"
  assertTrue  "expected MCIR"  "[ -r ./foo/bar/pass-MCIR.png ]"
}

. shunit2
