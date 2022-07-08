## Library for generating a website

WXRX_WEB_DIR=${WXRX_WEB_DIR:=~/wxrx/web}
WXRX_WEB_TEMPLATES=${WXRX_WEB_TEMPLATES:="${WXRX_WEB_DIR}/templates"}
WXRX_WEB_PUBDIR=${WXRX_WEB_PUBDIR:="${WXRX_WEB_DIR}/public"}

# Determine the path of a template
# @param name
# @output path to template
# @return non-zero if path does not exist
function template_path() {
  local file=${WXRX_WEB_TEMPLATES}/${1}.template
  local fallback="${rootdir}/lib/web-templates/${1}.template"
  if [ -f "$file" ]; then
    echo $file
    return
  elif [ -f "$fallback" ]; then
    echo $fallback
    return
  fi
  return 1
}

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

# Moves a file to the WXRX_WEB_PUBDIR
# @param file path
# @param destination path (optional), if not supplied the path part of the first argument is used
# @side_effect copies file in first arg to the WXRX_WEB_PUBDIR tree
# @output relative path (from WXRX_WEB_PUBDUR)
# @deprecated - use publish_file
function move_to_public() {
  src=${1}
  relative_path=$([[ ${2} =~ \/$ ]] && echo "${2}${1}" || echo "${2:-${1}}")
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
