#!/bin/bash

JEKYLL_TEMPLATE="${HOME}/.notes/templates/jekyll-post-template.md"
JEKYLL_POSTSDIR="${HOME}/Dropbox/src/botwerks/posts"

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y-%m-%d")

echo -n "post title: "
read POST_TITLE

#  title cleanup                | non-printable      | punctuation       | compress & replace spaces
FILE_TITLE=$(echo ${POST_TITLE} | tr -dc "[:print:]" | tr -d "[:punct:]" | tr -s "[:space:]" "-")
POST_FILE="${JEKYLL_POSTSDIR}/${DATESTAMP}-${FILE_TITLE}.md"
echo ${POST_FILE}

# check to make sure there isn't a post there already. if so, error out and make them fix it.
# otherwise, do the necessary search and replace and dump to a file

if [ -f "${POST_FILE}" ]; then
  echo "ERROR: POST FILE EXISTS - DEAL WITH THIS MANUALLY"
  echo "POST FILE: ${POST_FILE}"
  ${VISUAL} ${POST_FILE}
  exit
else 
  cat ${JEKYLL_TEMPLATE} | sed "s/%%_DATE_%%/${TIMESTAMP}/" \
      | sed "s/%%_TITLE_%%/${POST_TITLE}/" > ${POST_FILE}
  echo "POST FILE: ${POST_FILE}"
  ${VISUAL} ${POST_FILE}
fi






