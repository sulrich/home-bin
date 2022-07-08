#!/bin/bash

# script to generate a blog post for hugo's consumption.
#
# NOTE: this expects that the HUGO_DIR has been specified as
# appropriate for the host this script is being run on.
#
HUGO_POSTDIR="${HUGO_DIR}/content/post"
LINKS_TEMPLATE="${HOME}/.home/templates/markdown/links-post.md"

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
DATELINK=$(date +"%d-%b, %Y")
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y%m%d")

function print_usage() {
  cat <<EOF

mklinks.sh 

  generate a quicklink entry with the url that's currenly on the clipboard. use
  my typical date format with the date-(am|pm)-links.md filename format.

EOF

}


# make sure that the local repo is current
cd "${HUGO_DIR}" || exit
git pull

if [ $(date +"%H") -lt 12 ]
then
  DAY_SUFFIX="am"
  DAY_SUFFIX_TITLE="morning"
else
  DAY_SUFFIX="pm"
  DAY_SUFFIX_TITLE="afternoon"
fi

POST_FILE="${HUGO_POSTDIR}/${DATESTAMP}-${DAY_SUFFIX}-links.md"
echo "${POST_FILE}"

# ------------------------------------------------------------------------------
# check to make sure there isn't a post already. if there is, error out and
# make the user fix it.  otherwise, do the necessary search and replace and
# dump to a file in the right directory.
#

# make sure that the local git repo is current


if [ -f "${POST_FILE}" ]; then
  echo "ERROR: FILE EXISTS - DEAL WITH THIS MANUALLY"
  echo "POST FILE: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
  exit 0
else
  sed "s/%%DATELINK%%/${DATELINK}/g" < "${LINKS_TEMPLATE}" |\
  sed "s/%%DAY_SUFFIX_TITLE%%/${DAY_SUFFIX_TITLE}/g"       |\
  sed "s/%%TIMESTAMP%%/${TIMESTAMP}/g" >> "${POST_FILE}"
  pbpaste >> "${POST_FILE}"
  echo "editing: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
fi

