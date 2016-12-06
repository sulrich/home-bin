#!/bin/bash

SITE_DIR="${HOME}/src/botwerks"
HUGO_POSTDIR="post"

# JEKYLL_TEMPLATE="${HOME}/.notes/templates/jekyll-post-template.md"
# JEKYLL_POSTSDIR="${HOME}/src/botwerks/posts"

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y-%m-%d")

echo -n "post title: "
read POST_TITLE

#  title cleanup                | non-printable      
FILE_TITLE=$(echo ${POST_TITLE} | tr -dc "[:print:]" | \
               # punctuation     | compress & replace spaces
               tr -d "[:punct:]" | tr -s "[:space:]" "-")

# hugo builds everything from the content directory so there's no need to
# include __basedir__/content/... just go straight to the content/section type.
# 
POST_FILE="${HUGO_POSTDIR}/${FILE_TITLE}.md"
# echo ${POST_FILE}

cd ${SITE_DIR}
EDIT_FILE=$(hugo new ${POST_FILE})
EDIT_FILE=$(echo ${EDIT_FILE} | sed 's/ created//')
echo "editing: ${EDIT_FILE}"
${VISUAL} ${EDIT_FILE}

# the following is for use with jekyll.  preserved for reference
# ------------------------------------------------------------------------------
# check to make sure there isn't a post there already. if so, error out and
# make them fix it.  otherwise, do the necessary search and replace and dump to
# a file
# 
#if [ -f "${POST_FILE}" ]; then
#  echo "ERROR: POST FILE EXISTS - DEAL WITH THIS MANUALLY"
#  echo "POST FILE: ${POST_FILE}"
#  ${VISUAL} ${POST_FILE}
#  exit
#else
#  cat ${JEKYLL_TEMPLATE} | sed "s/%%_DATE_%%/${TIMESTAMP}/" \
#      | sed "s/%%_TITLE_%%/${POST_TITLE}/" > ${POST_FILE}
#  echo "POST FILE: ${POST_FILE}"
#  ${VISUAL} ${POST_FILE}
#fi
