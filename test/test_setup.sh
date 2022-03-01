#!/usr/bin/env bash
##
unit=$(realpath $(dirname "$0")/../setup.sh)
fixture_dir=$(realpath $(dirname "$0")/fixtures)

# This is a 
test_install_from_targz() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  installPath=${SHUNIT_TMPDIR}/setup/wxtoimg-root
  tarfile=${SHUNIT_TMPDIR}/setup/download.tgz
  # TODO: Avoid reaching out to the web
  url='https://static.kenbarbour.com/download/wxtoimg-linux64-2.10.11-1.tar.gz'
  source ${unit}
  mkdir -p $(dirname ${tarfile})
  mkdir -p ${installPath}

  install_from_targz "${url}" "${installPath}" "${tarfile}" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 exit status" $?
  assertTrue "expected downloaded file to exist" "[ -f ${tarfile} ]"
  assertNull "unexpected error" "`cat $stderrF`"
  assertTrue "expected wxtoimg binary" "[ -f ${installPath}/usr/local/bin/wxtoimg ]"
  assertTrue "expected wxmap binary" "[ -f ${installPath}/usr/local/bin/wxmap ]"
  cat ${stderrF}

}

test_install_wxtoimg() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  installPath=${SHUNIT_TMPDIR}/setup/wxtoimg-root
  tarfile=${SHUNIT_TMPDIR}/setup/download.tgz
  url='https://static.kenbarbour.com/download/wxtoimg-linux64-2.10.11-1.tar.gz'
  source ${unit}
  mkdir -p $(dirname ${tarfile})
  mkdir -p ${installPath}

  install_wxtoimg "${url}" "${installPath}" "${tarfile}" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 exit status" $?
  assertNull "unexpected error" "`cat $stderrF`"
  assertTrue "expected wxtoimg binary" "[ -f ${installPath}/usr/local/bin/wxtoimg ]"
  assertTrue "expected wxmap binary" "[ -f ${installPath}/usr/local/bin/wxmap ]"
  cat ${stderrF}
}

test_install_predict() {
  stdoutF=${SHUNIT_TMPDIR}/stdout
  stderrF=${SHUNIT_TMPDIR}/stderr
  installPath=${SHUNIT_TMPDIR}/setup/predict-root
  tarfile=${SHUNIT_TMPDIR}/setup/download-predict.tgz
  url='https://www.qsl.net/kd2bd/predict-2.2.7.tar.gz'
  source ${unit}
  mkdir -p $(dirname ${tarfile})
  mkdir -p ${installPath}

  install_predict "${url}" "${installPath}" "${tarfile}" >${stdoutF} 2>${stderrF}
  rtrn=$?
  assertTrue "expected 0 exit status" $?
  assertNull "unexpected error" "`cat $stderrF`"
}

. shunit2
