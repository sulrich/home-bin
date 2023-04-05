#!/bin/bash

# script to generate a blog post for hugo's consumption.
#
# NOTE: this expects that the HUGO_DIR has been specified as
# appropriate for the host this script is being run on.
#
HUGO_POSTDIR="${HUGO_DIR}/content/post"
POST_TEMPLATE="${HOME}/.home/templates/markdown/blog-post.md"

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y%m%d-%H%M%S")

function print_usage() {
  cat <<EOF

mkpost.sh (-c|--city "city" | -a|--auto-locate)

  generate post using a city provided on the command line with the -c arg or if
  run on a mac os system, use the CoreLocateCLI command to determine the
  location and populate the interesting fields in the template.

EOF

}

if [ $# -eq 0 ]
then
  print_usage
  exit 1
fi

# handle command line args
while [ "$1" != "" ]; do
  case $1 in
    -c | --city )
      shift
      ARG_CITY="$1"
      ;;
    -a | --auto-locate )
      shift
      ARG_CITY=""
      ;;
    * )
      print_usage
      exit 1
  esac
  shift
done

if [ "$ARG_CITY" != "" ]
then
  CITY=${ARG_CITY}
  LOCATION=${ARG_CITY}
else
  LOCATION_DATA=$(eval '/usr/bin/shortcuts run getCoreLocationData | cat')
  CITY=$(jq -r '.city' <<<"${LOCATION_DATA}")
  STATE=$(jq -r '.state' <<<"${LOCATION_DATA}")
  LOCATION="${CITY}, ${STATE}"
fi

WEATHER=$(curl -s "http://wttr.in/${CITY}?format=+%c(%C)+%t(%f)+")
LOCATION=$(echo "${LOCATION}" | tr '[:upper:]' '[:lower:]')

# make sure that the local repo is current
cd "${HUGO_DIR}" || exit
git pull

# get the post title
echo -n "post title: "
read -r POST_TITLE

#  title cleanup                    | non-printable
# FILE_TITLE=$(echo "${POST_TITLE}" | tr -dc "[:print:]" | \
#                # punctuation      | compress & replace spaces
#                 tr -d "[:punct:]" | tr -s "[:space:]" "-")
POST_FILE="${HUGO_POSTDIR}/${DATESTAMP}.md"
echo "${POST_FILE}"

# ------------------------------------------------------------------------------
# check to make sure there isn't a post already. if there is, error out and
# make the user fix it.  otherwise, do the necessary search and replace and
# dump to a file in the right directory.
#
if [ -f "${POST_FILE}" ]; then
  echo "ERROR: POST FILE EXISTS - DEAL WITH THIS MANUALLY"
  echo "POST FILE: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
  exit 1
else
  sed "s/%%TITLE%%/${POST_TITLE}/g" < "${POST_TEMPLATE}"                |\
  sed "s/%%WEATHER%%/${WEATHER}/g" | sed "s/%%LOCATION%%/${LOCATION}/g" |\
  sed "s/%%TIMESTAMP%%/${TIMESTAMP}/g" >> "${POST_FILE}"
  echo "editing: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
fi
