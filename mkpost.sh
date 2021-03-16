#!/bin/bash

# script to generate a blog post for hugo's consumption.
#
# NOTE: this expects that the HUGO_DIR has been specified as
# appropriate for the host this script is being run on.
#
HUGO_POSTDIR="${HUGO_DIR}/content/post"
POST_TEMPLATE="${HOME}/.templates/markdown/blog-post.md"

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y%m%d-%H%M%S")
LOCATION=$(CoreLocationCLI -format "%locality, %administrativeArea")
CITY=$(CoreLocationCLI -format "%latitude,%longitude")
URL="http://wttr.in/~${CITY}?format=+%c\(%C)+%t"
WEATHER=$(curl -s "http://wttr.in/~${CITY}?format=+%c\(%C)+%t") 

echo -n "post title: "
read -r POST_TITLE

#  title cleanup                  | non-printable
# FILE_TITLE=$(echo "${POST_TITLE}" | tr -dc "[:print:]" | \
#                # punctuation     | compress & replace spaces
#                tr -d "[:punct:]" | tr -s "[:space:]" "-")

POST_FILE="${HUGO_POSTDIR}/${DATESTAMP}.md"
echo "${POST_FILE}"

# ------------------------------------------------------------------------------
# check to make sure there isn't a post already. if there is, error out and
# make them fix it.  otherwise, do the necessary search and replace and dump to
# a file
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

