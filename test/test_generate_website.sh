#!/usr/bin/env sh
## Runs automated tests
## 
## Usage: __PROG__ [options]
##
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../generate_website.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

test_find_manifest_files() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  expectedF=${SHUNIT_TMPDIR}/expected
  pushd ${fixture_dir}/test_generate_website >/dev/null
  source ${unit}
    find_manifest_files >${stdoutF} 2>${stderrF}
    rtrn=$?
    assertTrue "expected 0 return status" ${rtrn}
    assertNotNull "expected output to stdout" "`cat ${stdoutF}`"
    assertNull "unexpected output to stderr" "`cat ${stderrF}`"
    cat << EOF >${expectedF}
bar-passes/noaa_15-1643805264-manifest.txt
foo-passes/noaa_15-1643805264-manifest.txt
noaa_15-1643805264-manifest.txt
EOF
    assertNull "diff found in output" "`diff \"${expectedF}\" \"${stdoutF}\"`"
  popd >/dev/null
}

# Using a fixture directory with a manifest, subdirs (also containing manifests)
# generate_website should mirror the directory structure and generate HTML for
# each manifest
test_generate_pages() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  expectedF=${SHUNIT_TMPDIR}/expected
  WXRX_WEB_PUBDIR=${SHUNIT_TMPDIR}/test_generate_website/public
  WXRX_WEB_TEMPLATES=${fixture_dir}/test_generate_website/templates
  data_dir=${fixture_dir}/test_generate_website
  source ${unit}

  pushd ${data_dir} >/dev/null
  generate_pages >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 return status" ${rtrn}
  assertNull "unexpected output to stderr" "`cat ${stderrF}`"
  assertTrue "expected html file" "[ -f ${WXRX_WEB_PUBDIR}/noaa_15-1643805264.html ]"
  assertTrue "expected directory foo-passes" "[ -f ${WXRX_WEB_PUBDIR}/foo-passes/noaa_15-1643805264.html ]"
  assertTrue "expected directory bar-passes" "[ -f ${WXRX_WEB_PUBDIR}/bar-passes/noaa_15-1643805264.html ]"
    cat << EOF >${expectedF}
1643805264	bar-passes/noaa_15-1643805264.html	bar-passes/noaa_15-1643805264-MCIR.png
1643805264	foo-passes/noaa_15-1643805264.html	foo-passes/noaa_15-1643805264-MCIR.png
1643805264	noaa_15-1643805264.html	noaa_15-1643805264-MCIR.png
EOF
  assertNull 'found diff in expected output' "`diff ${stdoutF} ${expectedF}`"

  diff "${expectedF}" "${stdoutF}"

  cat "${stderrF}"
  popd >/dev/null
}

test_generate_website() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  WXRX_WEB_TEMPLATES=${fixture_dir}/test_generate_website/templates
  WXRX_WEB_PUBDIR=${SHUNIT_TMPDIR}/test_generate_website/public
  mkdir -p "${WXRX_WEB_PUBDIR}"
  source ${unit}
  pushd ${fixture_dir}/test_generate_website >/dev/null

  generate_website >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 return status" ${rtrn}
  assertNull "unexpected stderr" "`cat ${stderrF}`"
  assertTrue "expected index file" "[ -f ${WXRX_WEB_PUBDIR}/index.html ]"
  assertTrue "expected pass html"  "[ -f ${WXRX_WEB_PUBDIR}/noaa_15-1643805264.html ]"
  assertTrue "expected pass image" "[ -f ${WXRX_WEB_PUBDIR}/noaa_15-1643805264-MCIR.png ]"
  assertTrue "expected pass audio" "[ -f ${WXRX_WEB_PUBDIR}/noaa_15-1643805264.wav ]"
  assertTrue "expected bar-passes directory" "[ -d ${WXRX_WEB_PUBDIR}/bar-passes ]"
  assertTrue "expected html"  "[ -f ${WXRX_WEB_PUBDIR}/bar-passes/noaa_15-1643805264.html ]"
  assertTrue "expected image" "[ -f ${WXRX_WEB_PUBDIR}/bar-passes/noaa_15-1643805264-MCIR.png ]"
  assertTrue "expected audio" "[ -f ${WXRX_WEB_PUBDIR}/bar-passes/noaa_15-1643805264.wav ]"
  assertTrue "expected foo-passes directory" "[ -d ${WXRX_WEB_PUBDIR}/foo-passes ]"
  assertTrue "expected html"  "[ -f ${WXRX_WEB_PUBDIR}/foo-passes/noaa_15-1643805264.html ]"
  assertTrue "expected image" "[ -f ${WXRX_WEB_PUBDIR}/foo-passes/noaa_15-1643805264-MCIR.png ]"
  assertTrue "expected audio" "[ -f ${WXRX_WEB_PUBDIR}/foo-passes/noaa_15-1643805264.wav ]"
 
  popd >/dev/null
}

test_publish_file() {
  WXRX_WEB_PUBDIR=${SHUNIT_TMPDIR}/test_generate_website/publish_file
  fileToMove="${fixture_dir}/test_generate_website/noaa_15-1643805264.wav" 
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  source ${unit}

  ## Test publish to a subdir
  publish_file "${fileToMove}" "foo/bar" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 exit status" ${rtrn}
  assertNull "unexpected error output" "`cat ${stderrF}`"
  assertEquals "noaa_15-1643805264.wav" "`cat ${stdoutF}`"
  assertTrue "expected file" "[ -f ${WXRX_WEB_PUBDIR}/foo/bar/noaa_15-1643805264.wav ]"

  # Test publish to root
  publish_file "${fileToMove}" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 exit status" ${rtrn}
  assertNull "unexpected error output" "`cat ${stderrF}`"
  assertEquals "noaa_15-1643805264.wav" "`cat ${stdoutF}`"
  assertTrue "expected file" "[ -f ${WXRX_WEB_PUBDIR}/noaa_15-1643805264.wav ]"

  cat "${stderrF}"
}

test_render_index() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  expectedF=${SHUNIT_TMPDIR}/expected
  WXRX_WEB_TEMPLATES=${fixture_dir}/test_generate_website/templates
  source ${unit}

  render_index "Expected Title" "Generated Timestamp" << EOF >${stdoutF} 2>${stderrF}
1643805264	bar-passes/noaa_15-1643805264.html	bar-passes/noaa_15-1643805264-MCIR.png
1643805264	foo-passes/noaa_15-1643805264.html	foo-passes/noaa_15-1643805264-MCIR.png
1643805264	noaa_15-1643805264.html	noaa_15-1643805264-MCIR.png
EOF

  rtrn=$?
  assertTrue "expected 0 return status" ${rtrn}
  assertNotNull "expected output" "`cat ${stdoutF}`"
  assertNull "unexpected stderr" "`cat ${stderrF}`"
  assertNotNull 'expected a title in output' "`grep -F 'Expected Title' ${stdoutF}`"
  assertNotNull 'expected generated date in output' "`grep -F 'Generated Timestamp' ${stdoutF}`"
  assertNotNull 'expected url' "`grep -F 'bar-passes/noaa_15-1643805264.html' ${stdoutF}`"
}


test_render_page() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  WXRX_WEB_TEMPLATES=${fixture_dir}/test_generate_website/templates
  source ${unit}

  render_page noaa_15-1643805264.wav noaa_15-1643805264-therm.png noaa_15-1643805264-MCIR.png >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 return status" ${rtrn}
  assertNotNull "expected output to stdout" "`cat ${stdoutF}`"
  assertNull 'unexpected message to stderr' "`cat ${stderrF}`"
  cat $stderrF

  assertNotNull 'expected wavfile in markup' "`grep 'noaa_15-1643805264.wav' ${stdoutF}`"
  assertNotNull 'expected thermal image' "`grep 'noaa_15-1643805264-therm.png' ${stdoutF}`"
  assertNotNull 'expected MCIR image' "`grep 'noaa_15-1643805264-MCIR.png' ${stdoutF}`"
  assertNotNull 'expected title text' "`grep -F 'Wed Feb 02 07:34:24 EST 2022' ${stdoutF}`"
  assertNotNull 'expected a description' "`grep -F 'NOAA-15 therm recorded' ${stdoutF}`"
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

test_timestamp_from_filename() {
  source $unit
  assertEquals "1644452667" "$(timestamp_from_filename foo-1644452667-bar.baz)"
}


. shunit2
