## Library for generating a website

WXRX_WEB_DIR=${WXRX_WEB_DIR:=~/wxrx/web}
WXRX_WEB_TEMPLATES=${WXRX_WEB_TEMPLATES:="${WXRX_WEB_DIR}/templates"}
WXRX_WEB_PUBDIR=${WXRX_WEB_PUBDIR:="${WXRX_WEB_DIR}/public"}


function render_index_item() {
  url=${1}
  title=${2}
  thumbnail=${3}
  cat ${WXRX_WEB_TEMPLATES}/item.template |
  url="${url}" title="${title}" thumbnail="${thumbnail}" envsubst
}

function template_path() {
  echo ${WXRX_WEB_TEMPLATES}/${1}.template
}

##
# Replaces every "{{$1}}" in stdin with $2
# @param VAR
# @param replacement
function template_subst() {
  # ~ is a delimiter, but ~ in the replacement is escaped
  replacement=$(echo ${2} | tr -d '\n')
  sed -e "s~{{${1}}}~${replacement//'~'/'\~'}~g"
}

# Replaces {{VAR}} from stdin with contents of file $2
# @param VAR
# @param file replacement
function template_fsubst() {
  echo "TODO: implement website_generatorlib.sh:${0}"
}

function move_to_public() {
  src=${1}
  relative_path=${2:-${1}}
  dest=${WXRX_WEB_PUBDIR}/${relative_path}
  mkdir -p $(dirname ${dest})
  cp ${src} ${dest}
  echo ${relative_path}
}

function publish_audio() {
  move_to_public "${1}" "audio/${1}"
}

function publish_image() {
  move_to_public "${1}" "img/${1}"
}

function publish_file() {
  move_to_public "${1}"
}
