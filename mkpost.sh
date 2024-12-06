#!/bin/bash

# script to generate a blog post for hugo's consumption.
#
# NOTE: this expects that the HUGO_DIR has been specified as
# appropriate for the host this script is being run on.
#

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y%m%d-%H%M%S")
YEAR=$(date +"%Y")

function print_usage() {
  cat <<EOF

mkpost.sh -t|--type [post|til|link]

if a type has been provided (default is "post") the appropriate template and
posting directory will be used. if the type is something other than "link" the
script will prompt for a list of comma separated tags to fold into the mix.

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
    -t | --type)
      shift
      ARG_TYPE="$1"
      ;;
    * )
      print_usage
      exit 1
  esac
  shift
done

if [ "${ARG_TYPE}" == "til" ]
then
  TEMPLATE="${HOME}/.home/templates/markdown/blog-til.md"
  PAGE_DIR="til"
elif [ "${ARG_TYPE}" == "link" ]
then
  TEMPLATE="${HOME}/.home/templates/markdown/blog-links.md"
  PAGE_DIR="links"
  DATELINK=$(date +"%d-%b-%Y")
else
  TEMPLATE="${HOME}/.home/templates/markdown/blog-post.md"
  PAGE_DIR="posts"
fi

# make sure that the local repo is current
cd "${HUGO_DIR}" || exit
# git pull

# get the post title
echo -n "post title: "
read -r POST_TITLE

# get tags
if [ "${ARG_TYPE}" != "link" ]
then
  echo -n "post tags (comma separated): "
  read -r TAGS
fi

#  title cleanup                    | non-printable
# FILE_TITLE=$(echo "${POST_TITLE}" | tr -dc "[:print:]" | \
#                # punctuation      | compress & replace spaces
#                 tr -d "[:punct:]" | tr -s "[:space:]" "-")
POST_FILE="${HUGO_DIR}/content/${PAGE_DIR}/${DATESTAMP}.md"
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
  sed "s/%%TITLE%%/${POST_TITLE}/g" < "${TEMPLATE}"                     |\
  sed "s/%%WEATHER%%/${WEATHER}/g" | sed "s/%%LOCATION%%/${LOCATION}/g" |\
  sed "s/%%YEAR%%/${YEAR}/g" | sed "s/%%TIMESTAMP%%/${TIMESTAMP}/g"     |\
  sed "s/%%TAGYEAR%%/${YEAR}/g" | sed "s/%%DATELINK%%/${DATELINK}/g"    |\
  sed "s/%%TAGS%%/${TAGS}/g" >> "${POST_FILE}"
  echo "editing: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
fi
