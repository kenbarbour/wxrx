#!/usr/bin/env sh
## Runs automated tests
## 
## Usage: __PROG__ [options]
##
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../generate_website.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)


test_timestamp_from_filename() {
  source $unit
  assertEquals "1644452667" "$(timestamp_from_filename foo-1644452667-bar.baz)"
}

test_render_pass_audio() {
  WXRX_WEB_DIR=${SHUNIT_TMPDIR}
  mkdir -p ${WXRX_WEB_DIR}/templates
  mkdir -p ${WXRX_WEB_DIR}/public
  echo << EOF > ${WXRX_WEB_DIR}/templates/pass-audio.template
<audio>
{{WAV_FILE}}
</audio>
EOF
}

test_render_page() {
  WXRX_WEB_TEMPLATES=${fixture_dir}/test_generate_website/templates
  stdoutF=${SHUNIT_TMPDIR}/stout
  stderrF=${SHUNIT_TMPDIR}/stderr
  source ${unit}

  render_page noaa_15-1643805264.wav noaa_15-1643805264-therm.png noaa_15-1643805264-MCIR.png >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 return status" ${rtrn}
  assertNotNull "expected output to stdout" "`cat ${stdoutF}`"
  assertNull 'unexpected message to stderr' "`cat ${stderrF}`"

  #TODO: test for expected URLs and values in output

  assertNotNull 'expected wavfile in markup' "`grep 'noaa_15-1643805264.wav' ${stdoutF}`"
  assertNotNull 'expected thermal image' "`grep '-therm.png' ${stdoutF}`"
  assertNotNull 'expected MCIR image' "`grep '-MCIR.png' ${stoutF}`"

}



. shunit2
