#!/usr/bin/env bash
## Generates a "website" from decoded satellite data
## 
## Usage: __PROG__ [options]
##
## Run from the root of a directory tree containing manifest files.
## Each manifest file is used to generate a static web-page.
## Web pages are built from templates in WXRX_WEB_TEMPLATES and
## placed in WXRX_WEB_PUBDIR
##
## Put this directory on your web server or sync to your online storage "bucket".
##
prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath ${BASH_SOURCE[0]}))
source ${rootdir}/lib/utils.sh
source ${rootdir}/lib/website_generatorlib.sh

# Makes an attempt to describe an image based on the filename
# This takes advantage of predictable image filenames generated
# by wxrx
# @param filename
# @output string description to stdout
function description_from_filename() {
  local filename=${1} satname= timestamp= enhancement= re=
  re="(noaa_1[589])-([0-9]+)-([a-Z\-]+)"
  if [[ $filename =~ $re ]]; then
    satname=$(echo "${BASH_REMATCH[1]}" | awk '{ gsub("_", "-"); print toupper($0) }')
    timestamp=$(date -d "@${BASH_REMATCH[2]}" '+%a %b %d %T %Z %Y')
    enhancement=${BASH_REMATCH[3]}
    echo "${satname} $enhancement recorded ${timestamp}"
  else
    echo $(basename ${filename} .png)
  fi
}

# Searches from a directory for manifest files
# @param directory
# @output path to manifest files from directory
function find_manifest_files() {
  find ${1:-.} -name "*-manifest.txt" |
  sed 's/^\.\///' |
  sort
}

function find_valid_manifest_files() {
  for manifest in $(find_manifest_files ${1:-.})
  do
    validate_manifest "${manifest}" || {
      logwarn "Skipping invalid manifest %s" "${manifest}"
      continue
    }
    echo "${manifest}"
  done
}

# @param manifest file
# @param path (in WXRX_WEB_PUBDIR) to publish files to
# @output relative path to image file from WXRX_WEB_PUBDIR
# @side-effect generates an image file in WXRX_WEB_PUBDIR/{path}
function generate_manifest_thumbnail() {
  local manifest=${1}
  local manifestdir=$(dirname ${manifest})
  local relpath=${2}
  local basename=$(basename "${manifest}" "manifest.txt")
  local dest=${relpath}/${basename}thumbnail.png
  if [ -f "${WXRX_WEB_PUBDIR}/${dest}" ]; then
    logdebug "thumbnail already exists: %s" "${WXRX_WEB_PUBDIR}/${dest}"
    echo $dest
    return 0
  fi
  local file=$(grep 'MCIR' ${manifest} | head -n 1)
  if [ -z "${file}" ]; then
    local file=$(grep 'therm' ${manifest} | head -n 2)
  fi
  if [ -z "${file}" ]; then
    local file=$(grep 'png' ${manifest} | head -n 2)
  fi

  convert ${manifestdir}/${file} -colors 256 -thumbnail 500x500^ -gravity center -extent 500x500 ${WXRX_WEB_PUBDIR}/${dest}
  echo $dest
}

# Generates a website by inspecting the directory tree at '.'
# and publishing files to WXRX_WEB_PUBDIR
# @param path to data (manifests will be searched from this tree)
# @side-effect generates files in WXRX_WEB_PUBDIR
# @output tab delimited: timestamp, html, thumbnail
function generate_pages() {
  local data_dir=${1:-.}
  for manifest in $(find_valid_manifest_files "${data_dir}")
  do
    # each manifest file should turn into an html file, within
    # WXRX_WEB_PUBDIR, mirroring the manifest path
    relpath=$(dirname "${manifest}")
    timestamp=$(timestamp_from_filename "${manifest}")
    html_src="${relpath}/$(basename ${manifest} -manifest.txt).html"
    html_src=$(echo "${html_src}" | sed 's/^\.\///')
    html_path="${WXRX_WEB_PUBDIR}/${html_src}"
    files=$(publish_manifest "${manifest}" "${relpath}")
    thumbnail_src=$(generate_manifest_thumbnail ${manifest} "${relpath}")
    if [ -z "${thumbnail_src}" ]; then
      logerr "Error generating thumbnail for %s" "${manifest}"
      continue
    fi
    if file_is_newer "${manifest}" "${html_path}"; then
      mkdir -p "$(dirname ${html_path})"
      render_page ${files} >"${html_path}"
    else
      logdebug "Already built %s" "${html_path}"
    fi
    printf "%s\t%s\t%s\n" "${timestamp}" "${html_src}" "${thumbnail_src}"
  done
}

function generate_website() {
  local data_dir=${1}
  local index=${2:-index.html}
  generate_pages "${data_dir}" | sort -r | head -n10 | render_index > ${WXRX_WEB_PUBDIR}/${index}
}

function file_is_newer() {
  local a=${1}
  local b=${2}
  if [ ! -f ${b} ]; then
    return 0; # yes, b file DNE
  elif [ ${a} -nt ${b} ]; then
    return 0; # yes, a is newer
  fi
  return 1; # no, not newer
}

# Reads a manifest file
# @param manifest file
# @param path relative to WXRX_WEB_PUBDIR
# @side-effect creates files in public web directory
# @output filenames
# TODO: move these files
function publish_file() {
  src=${1}
  dest_path=${2}
  dest=${WXRX_WEB_PUBDIR}/${dest_path}/$(basename ${src})
  if file_is_newer "${src}" "${dest}"; then
    mkdir -p $(dirname ${dest})
    case "${dest##*.}" in
      'png')
        logdebug "Processing PNG with imagemagick %s" "${dest}"
        convert "${src}" \
          -colors 255 \
          -define png:compression-filter=0 \
          -define png:compression-level=9 \
          -define png:compression-strategy=0 \
          "${dest}"
        ;;
      *)
        cp ${src} ${dest}
    esac
  else
    logdebug "Not modifying file %s, src is not newer" "${dest}"
  fi
  echo $(basename "${dest}")
}

# Publishes the contents of a manifest to web
# @param manifest file
# @param relative path of files in manifest to WXRX_WEB_PUBDIR
# @output filenames (from publish_file)
function publish_manifest() {
  manifest=${1}
  relpath=${2:-}
  manifest_dir=$(dirname ${manifest})
  for file in $(cat $manifest)
  do
    publish_file "${manifest_dir}/$file" "$relpath"
  done
}

# Renders an index file from input from STDIN
# Input should be tab-delimited TIMESTAMP, URL, THUMBNAIL_URL
# The output of `generate_pages` is expected to be used here
# @param Title (optional)
# @param Generated timestamp (optional)
# @input tab delimited items to add to index
# @output rendered markup to stdout
function render_index() {
  title=${1:-Latest Satellite Passes}
  generated_at=${2:-$(date '+%a %b %d %T %Z %Y')}
  items=( )
  while read -r line
  do
    timestamp=$(echo "${line}" | cut -f1)
    url=$(echo "${line}" | cut -f2)
    heading=$(date -d "@${timestamp}" '+%a %b %d %T %Z %Y')
    thumbnail=$(echo "${line}" |cut -f3)
    item=$(render_index_item "${url}" "${heading}" "${thumbnail}")
    items+=( "${item}" )
  done

  content=$(echo "${items[@]}")

  document_body=$(cat $(template_path "index") |
    template_subst CONTENT "${content}")

  cat $(template_path "document") |
    template_subst CONTENT "${document_body}" |
    template_subst TITLE "${title}" |
    template_subst GENERATED_AT "${generated_at}"
  
}

# Renders the markup for an item to include in the site inded
# @param url path to item (usually html page)
# @param string Title
# @param string thumbnail image
# @output markup to stdout
function render_index_item() {
  url=${1}
  title=${2}
  thumbnail=${3}
  cat ${WXRX_WEB_TEMPLATES}/item.template |
    template_subst URL "${url}" |
    template_subst HEADING "${title}" |
    template_subst THUMBNAIL "${thumbnail}"
}

# Render the markup to represent a full HTML page
# for every item associated with a pass
# @param ... file path to item from manifest
# @output rendered markup to stdout
function render_page() {
  local heading= content= body=
  for file in $@
  do
    case $file in
      *.wav)
        heading=${heading:-$(timestring_from_filename "${file}")}
        content=$(echo "${content}" "$(render_pass_audio "$file")")
        ;;
      *.png)
        heading=${heading:-$(timestring_from_filename "${file}")}
        content=$(echo "${content}" "$(render_pass_image "$file")")
        ;;
      *)
        content="${content}<!-- unknown file type: ${file} -->"
        ;;
    esac
  done

  body=$(cat $(template_path pass) |
    template_subst TITLE "${heading}" |
    template_subst CONTENT "${content}"
  )

  cat $(template_path document) |
    template_subst TITLE "${heading}" |
    template_subst CONTENT "${body}" |
    template_subst GENERATED_AT "$(date '+%a %b %d %T %Z %Y')"
}

# Renders the markup for a pass audio file
# Requires a file in $WXRX_WEB_DIR/templates/pass-audio.template
# @param file path to render
# @output markup to stdout
function render_pass_audio() {
  local path=${1}
  cat $(template_path pass-audio) |
    template_subst WAV_FILE "${path}"
}

# Renders the markup for a pass image file
# Requires a file in $WXRX_WEB_DIR/templates/pass-image.template
# @param image file path to render markup for
# @output markup to stdout
function render_pass_image() {
  local path=${1} caption=
  path=${1}
  caption=$(description_from_filename $(basename "${1}"))
  cat $(template_path pass-image) |
    template_subst SRC "${path}" |
    template_subst ALT "Decoded satellite image" |
    template_subst CAPTION "${caption}"
}

function validate_manifest() {
  local dir=$(dirname "${1}")
  for file in `cat ${1}`
  do
    if [ ! -f ${dir}/${file} ]; then
      logdebug "Missing file %s" "${dir}/${file}"
      return 1
    elif [ "$(wc -c <${dir}/${file})" -lt 50000 ]; then
      logdebug "File too small %s" "${dir}/${file}"
      return 2
    fi
  done
  return 0
}

function timestamp_from_file() {
  local filename=${1}
  date -d "@$(stat -c '%Y' $filename)" '+%a %b %d %T %Z %Y'
}

function timestamp_from_filename() {
  echo "${1}" | grep -oP -m1 '[0-9]{9,}'
}

function timestring_from_filename() {
  date -d "@$(timestamp_from_filename ${1})" '+%a %b %d %T %Z %Y'
}

function process_args() {
##  Options:
while (( "$#" ));
do

## --help, -h                   Help message
  case "${1}" in
    '--help' | '-h')
      usage
      exit
      ;;

# ## --force, -f                  Force rebuild of previously generated pages
#    '--force' | '-f')
#      rebuild_all=1
#      ;;

    *)
      logerr "Unknown option %s." ${1}
      usage
      exit 1
      ;;
  esac
  shift
done
}


# If sourced, return now
# The ensures sourcing script only gets libraries
if [ "${0}" != "${BASH_SOURCE[0]}" ]; then
  return
fi

# -- Do work below here --

process_args $@

data_dir=$(pwd)
log "Generating website\n\tdata source: %s\n\tweb root:  %s" "${data_dir}" "${WXRX_WEB_PUBDIR}"
generate_website
log "done"
