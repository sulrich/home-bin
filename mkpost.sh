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

# handle command line args
while [ "$1" != "" ]; do
  case $1 in
    -c | --city )
      shift
      ARG_CITY="$1"
      ;;
    * )
      usage
      exit 1
  esac
  shift
done

if [ "$ARG_CITY" != "" ];
then
  CITY=${ARG_CITY}
  LOCATION=${ARG_CITY}
else
  LOCATION=$(CoreLocationCLI -format "%locality, %administrativeArea")
  CITY=$(CoreLocationCLI -format "%latitude,%longitude")
fi

URL="http://wttr.in/~${CITY}?format=+%c\(%C)+%t"
WEATHER=$(curl -s "http://wttr.in/~${CITY}?format=+%c\(%C)+%t") 

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

