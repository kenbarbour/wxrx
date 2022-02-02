# Lines starting with '##' are intended for usage documentation
function usage() {
  grep '^##' "$prog" | sed -e 's/^##\s\?//' -e "s/__PROG__/$me/" 1>&2
}

function nowstr() {
  date -u +"%Y-%m-%dT%H:%M:%S%Z"
}

function log() {
  if [ -t 1 ]; then
    printf "$(tput setaf 2)[${me}]$(tput sgr0) ${1}\n" ${@:2}
  else
    printf "$(nowstr) [${me}] ${1}\n" ${@:2}
  fi
}

function logerr() {
  if [ -t 2 ]; then
    printf "$(tput setaf 1)[${me}]$(tput sgr0) ${1}\n" ${@:2}
  else
    printf "$(nowstr) [${me}] ${1}\n" ${@:2}
  fi
}
