#!/usr/bin/env bash
## Generates a "website" from decoded satellite data
## 
## Usage: __PROG__ [options] file
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
  filename=${1}
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

# @param manifest file
# @output path to image file
function generate_manifest_thumbnail() {
  #TODO: generate an actual thumbnail and move it to the web dir
  # skip if file exists, unless forced
  cat $1 | grep -m1 '\.png'
}

# Generates a website by inspecting the directory tree at '.'
# and publishing files to WXRX_WEB_PUBDIR
# @param path to data (manifests will be searched from this tree)
# @side-effect generates files in WXRX_WEB_PUBDIR
# @output tab delimited: timestamp, html, thumbnail
# TODO: avoid regenerating pages
function generate_pages() {
  data_dir=${1:-.}
  for manifest in $(find_manifest_files "${data_dir}")
  do
    # each manifest file should turn into an html file, within
    # WXRX_WEB_PUBDIR, mirroring the manifest path
    relpath=$(dirname "${manifest}")
    timestamp=$(timestamp_from_filename "${manifest}")
    html_src="${relpath}/$(basename ${manifest} -manifest.txt).html"
    html_src=$(echo "${html_src}" | sed 's/^\.\///')
    html_path="${WXRX_WEB_PUBDIR}/${html_src}"
    files=$(publish_manifest "${manifest}" "${relpath}")
    thumbnail_src="${relpath}/$(echo "$files" | head -n2 | tail -n1)"
    thumbnail_src=$(echo "${thumbnail_src}" | sed 's/^\.\///')
    mkdir -p "$(dirname ${html_path})"
    render_page ${files} >"${html_path}"
    printf "%s\t%s\t%s\n" "${timestamp}" "${html_src}" "${thumbnail_src}"
  done
}

function generate_website() {
  generate_pages | sort -r | head -n10 | render_index > ${WXRX_WEB_PUBDIR}/index.html
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
  mkdir -p $(dirname ${dest})
  cp ${src} ${dest}
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
  path=${1}
  cat $(template_path pass-audio) |
    template_subst WAV_FILE "${path}"
}

# Renders the markup for a pass image file
# Requires a file in $WXRX_WEB_DIR/templates/pass-image.template
# @param image file path to render markup for
# @output markup to stdout
function render_pass_image() {
  path=${1}
  caption=$(description_from_filename $(basename "${1}"))
  cat $(template_path pass-image) |
    template_subst SRC "${path}" |
    template_subst ALT "Decoded satellite image" |
    template_subst CAPTION "${caption}"
}

function timestamp_from_file() {
  filename=${1}
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

generate_website
