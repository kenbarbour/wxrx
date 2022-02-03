#!/usr/bin/env sh
## Generates a "website" from decoded satellite data
## 
## Usage: __PROG__ [options] file
##
## Supply one or more manifest files
## A manifest file is a text file containing the paths to every file used in
## a decoding, including the .wav file and every .png.
##
## Each manifest file is used to generate a static web-page.
##
## Put this directory on your web server or sync to your online storage "bucket".
##
prog="$0"
me=${HELP:-`basename "$prog"`}
rootdir=$(dirname $(realpath $0))
source ${rootdir}/lib/utils.sh

function generate_header() {
  heading=${1:-"Weather Satellite Images"}
  cat << __HEADER__
<!doctype html>
<html>
  <head>
    <title>${title:-${heading}}</title>
    <meta charset="utf-8">
  </head>
  <body>
    <header>
    <h1>${heading}</h1>
    </header>
__HEADER__
}

function generate_footer() {
  cat << __FOOTER__
    <footer>
    Generated $(date +%c), KO4UXG
    </footer>
  </body>
</html>
__FOOTER__
}

function generate_wavfile_html() {
  wavfile=${1}
  capture_date=$(date -d "@$(stat -c '%Y' ${wavfile})" '+%a %b %d %T %Z %Y')
  cat << __WAVFILE__
  <h2>
    <time>${capture_date}</time>
  </h2>
  <p>Hear the FM demodulated output from this pass, or decode it yourself:</p>
  <audio controls>
    <source src="${wavfile}" type="audio/wav">
    <a href="${wavfile}">$(basename ${wavfile})</a>
  </audio>
__WAVFILE__
}

function generate_image_html() {
  image=${1}
  image_caption="$(basename "${1}" .png) - Generated $(date -d "@$(stat -c '%Y' $1)" '+%a %b %d %T %Z %Y')"
  cat << __IMAGE__
  <figure style="max-width: 1024px; margin: 2rem auto 6rem;" >
    <a href="${image}">  
      <img src="${image}" style="width: 100%" alt="Decoded satellite image" />
    </a>
    <figcaption>$(description_from_filename ${image})</figcaption>
  </figure>
__IMAGE__
}

#
# @param manifest file
# @global rebuild_all read
# @side effect creates an .html file
function generate_from_manifest() {
  manifest=${1}
  outfile="$(basename "${manifest}" -manifest.txt).html"

  # count this file as processed
  html_files+=("$outfile")

  if [ -f $outfile ] && [ "$outfile" -nt "${manifest}" ]; then
    if [ $rebuild_all -gt 0 ]; then
      log "--force option used; Re-generating %s" "${outfile}"
    else
      log "%s already exists and is newer than manifest file. Skipping" "${outfile}"
      return
    fi
  fi

  log "Generating page %s from %s" "$outfile" "${manifest}"
  generate_header > ${outfile}
  echo '<article>' >> ${outfile}
  for file in $(cat ${manifest})
  do
    case $file in
      *.wav)
        log "Generating markup for wavfile %s" "${file}"
        generate_wavfile_html "${file}" >> ${outfile}
        ;;
      *.png)
        log "Generating markup for image %s" "${file}"
        generate_image_html "${file}" >> ${outfile}
        ;;
      *)
        logerr "Not sure what to do with this file: %s" "${file}"
        ;;
    esac
  done
  echo '</article>' >> ${outfile}
  generate_footer >> ${outfile}
}

function generate_index() {
  outfile="index.html"
  generate_header "Latest Satellite Passes" > ${outfile}
  for i in "${html_files[@]}"; do
    image=$(grep -m1 '<img ' $i)
    time=$(grep -m1 '<time' $i)
    cat << __PASSLIST__ >> ${outfile}
  <article><a href="${i}">
    <figure style="max-width: 200px; margin: 1rem auto 3rem;">
      ${image}
      <figcaption>Captured ${time}</figcaption>
    </figure>
  </a></article>
__PASSLIST__
  done
  generate_footer >> ${outfile}
}

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

html_files=()
rebuild_all=0
##  Options:
while (( "$#" ));
do

## --help, -h                   Help message
  case "${1}" in
    '--help' | '-h')
      usage
      exit
      ;;

## --force, -f                  Force rebuild of previously generated pages
    '--force' | '-f')
      rebuild_all=1
      ;;

    *)
      # if this is an unrecognized flag, log an error
      if [[ $1 == -* ]] ; then
        logerr "Unknown option %s.  If you meant to process the a file named '%s' use './%s'" ${1} ${1} ${1}
        usage
        exit 1
      fi
      generate_from_manifest ${1}
      ;;
  esac
  shift
done

if (( ${#html_files[@]} == 0 )); then
  logerr "No files processed.  Supply the path to one or more manifest files"
  usage
  exit 1
fi

# Generate index
log "Generating index"
generate_index

exit # normal exit
