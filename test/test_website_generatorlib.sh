##
prog="$0"
me=${HELP:-$(basename "$prog")}
rootdir=$(dirname $(dirname $(realpath ${BASH_SOURCE[0]})))
unit=${rootdir}/lib/website_generatorlib.sh

test_source_unit() {
  WXRX_WEB_DIR=${SHUNIT_TMPDIR}/test-source
  WXRX_WEB_TEMPLATES=${SHUNIT_TMPDIR}/test-source/foo
  WXRX_WEB_PUBDIR=${SHUNIT_TMPDIR}/test-source/bar
  source ${unit}

  assertEquals "${SHUNIT_TMPDIR}/test-source" "${WXRX_WEB_DIR}"
  assertEquals "${SHUNIT_TMPDIR}/test-source/foo" "${WXRX_WEB_TEMPLATES}"
  assertEquals "${SHUNIT_TMPDIR}/test-source/bar" "${WXRX_WEB_PUBDIR}"
}

test_template_path() {
  WXRX_WEB_TEMPLATES=${SHUNIT_TMPDIR}/template_path
  mkdir -p ${WXRX_WEB_TEMPLATES}
  source ${unit}

  touch ${WXRX_WEB_TEMPLATES}/foo.template

  assertEquals "${WXRX_WEB_TEMPLATES}/foo.template" "$(template_path foo)"

  template_path 'bar'
  retval=$?
  assertFalse "missing templates should have non-zero exit status" "$retval"
  assertEquals "" "$(template_path bar)"
}

test_template_subst() {
  source ${unit}

  actual=$(template_subst BAR "bar-baz" << EOF
<foo>{{BAR}}</foo>
EOF
)
  assertEquals "single substitution failed" "<foo>bar-baz</foo>" "${actual}"

  actual=$(template_subst BAR "qux" << EOF
<foo>{{BAR}}</foo><bar>{{BAR}}</bar>
EOF
)
  assertEquals "multiple substitution failed" "<foo>qux</foo><bar>qux</bar>" "${actual}"

  actual=$(template_subst FOO "~foo~" << EOF
<foo>{{FOO}}</foo>
EOF
)
  assertEquals "delimiter handled improperly" "<foo>~foo~</foo>" "${actual}"
}

test_move_to_public() {
  WXRX_WEB_DIR=${SHUNIT_TMPDIR}/move_to_public
  WXRX_WEB_TEMPLATES=${WXRX_WEB_DIR}/templates
  WXRX_WEB_PUBDIR=${WXRX_WEB_DIR}/public
  mkdir -p ${WXRX_WEB_TEMPLATES}
  mkdir -p ${WXRX_WEB_PUBDIR}
  source ${unit}

  pushd ${WXRX_WEB_DIR} > /dev/null

  touch testfile
  mkdir -p foo > /dev/null
  touch foo/testfile

  # moving ./testfile should put it in public/testfile
  path=$(move_to_public testfile)
  assertEquals 'testfile' "${path}"
  assertTrue 'file not moved' "[ -f ${WXRX_WEB_PUBDIR}/testfile ]"

  path=$(move_to_public foo/testfile) # expect public/foo/testfile
  assertEquals 'foo/testfile' "${path}"
  assertTrue 'file not moved with path' "[ -f ${WXRX_WEB_PUBDIR}/foo/testfile ]"

  path=$(move_to_public testfile bar) # expect public/bar
  assertEquals 'bar' "${path}"
  assertTrue 'file not moved with new name' "[ -f ${WXRX_WEB_PUBDIR}/bar ]"

  path=$(move_to_public testfile baz/) # expect public/baz/testfile
  assertEquals 'baz/testfile' "${path}"
  assertTrue 'file not moved to new path' "[ -f ${WXRX_WEB_PUBDIR}/baz/testfile ]"

  popd > /dev/null
}

. shunit2
