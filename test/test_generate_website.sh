#!/usr/bin/env sh
## Runs automated tests
## 
## Usage: __PROG__ [options]
##
prog="$0"
me=`basename "$prog"`

tmp_dir='./tmp'
mkdir -p ${tmp_dir}

# Lines starting with '##' are intended for usage documentation
function usage() {
  grep '^##' "$prog" | sed -e 's/^##\s\?//' -e "s/__PROG__/$me/" 1>&2
}

# Like printf, but prints to stderr with prettier formatting if TTY
function logerr() {
  if [ -t 2 ]; then
    printf "$(tput setaf 1)ERROR$(tput sgr0) ${1}\n" ${@:2} 1>&2
  else
    printf "${1}\n" ${@:2} 1>&2
  fi
}

testEquality() {
  assertEquals 1 1
}

testGenerateWebsite() {
  data_dir=${tmp_dir}/testGenerateWebsite/data
  web_pubdir=${tmp_dir}/testGenerateWebsite/public
  bin_path=$(realpath ../generate_website.sh)

  # setup a clean directory containing decoded pass data
  rm -Rf ${data_dir}
  rm -Rf ${web_pubdir}
  mkdir -p ${data_dir}
  mkdir -p ${web_pubdir}
  cp -p ./fixtures/test_generate_website/* ${data_dir}

  pushd ${data_dir}
  WXRX_WEB_PUBDIR=${web_pubdir} ${bin_path} *-manifest.txt
  
  # index file exists
  indexFile=${web_pubdir}/index.html
  assertTrue "${indexFile} not created" "[ -f ${indexFile} ]"

  popd

}

. shunit2
