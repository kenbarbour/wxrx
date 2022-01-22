
function nowstr() {
  date -u +"%Y-%m-%dT%H:%M:%S%Z"
}

function log() {
  printf "$(nowstr) ${1}\n" ${@:2}
}

function err() {
  log $@ 1>&2
}
