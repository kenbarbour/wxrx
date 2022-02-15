#!/usr/bin/env sh
## Runs automated tests
## 
## Usage: __PROG__ [options]
##
prog="$0"
me=`basename "$prog"`
unit=$(realpath $(dirname "$0")/../generate_website.sh)


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



. shunit2
