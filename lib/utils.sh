# Lines starting with '##' are intended for usage documentation
# Does nothing if not using stdout
function usage() {
  if [ -t 1 ]; then
    grep '^##' "$prog" | sed \
      -e 's/^##\s\?//' \
      -e "s/__PROG__/$me/" \
      -e "s|__DEFAULT_WXRX_WEB_PUBDIR__|${WXRX_WEB_PUBDIR:-undefined}|" \
      -e "s|__DEFAULT_WXRX_WEB_TEMPLATES__|${WXRX_WEB_TEMPLATES:-undefined}|" \
    1>&2
  fi
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
    printf "$(tput setaf 1)[${me}] ERROR:$(tput sgr0) ${1}\n" ${@:2} 1>&2
  else
    printf "$(nowstr) [${me}] ERROR: ${1}\n" ${@:2} 1>&2
  fi
}

function logwarn() {
  if [ -t 2 ]; then
    printf "$(tput setaf 3)[${me}] WARNING:$(tput sgr0) ${1}\n" ${@:2} 1>&2
  else
    printf "$(nowstr) [${me}] WARNING: ${1}\n" ${@:2} 1>&2
  fi
}

function logdebug() {
  if [ -z "${DEBUG}" ]; then
    return
  fi

  if [ -t 2 ]; then
    printf "$(tput setaf 4)[${me}] DEBUG:$(tput sgr0) ${1}\n" ${@:2} 1>&2
  else
    printf "$(nowstr) [${me}] DEBUG: ${1}\n" ${@:2} 1>&2
  fi
}
