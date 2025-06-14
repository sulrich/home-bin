#!/bin/bash

# script to generate a blog post for hugo's consumption.
#
# NOTE: this expects that the HUGO_DIR has been specified as
# appropriate for the host this script is being run on.
#

# validate required environment variables
if [[ -z "${HUGO_DIR:-}" ]]; then
    echo "ERROR: HUGO_DIR environment variable is not set" >&2
    exit 1
fi

if [[ -z "${VISUAL:-}" ]]; then
    echo "ERROR: VISUAL environment variable is not set" >&2
    exit 1
fi

# post timestamp sample: date: "2014-04-14 10:15:53 -0500"
readonly TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
readonly DATESTAMP=$(date +"%Y%m%d-%H%M%S")
readonly DATEFMT=$(date +"%Y%m%d")
readonly YEAR=$(date +"%Y")

function print_usage() {
  cat <<EOF

mkpost.sh -t|--type [post|til|link]

if a type has been provided (default is "post") the appropriate template and
posting directory will be used. if the type is something other than "link" the
script will prompt for a list of comma separated tags to fold into the mix.

EOF

}

function validate_input() {
    local input=$1
    # remove any potentially dangerous characters
    echo "$input" | tr -dc '[:alnum:][:space:]-_.,;()[]{}' || return 1
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

# get the post title with timeout
echo -n "post title: "
if ! read -r -t 60 POST_TITLE; then
    echo "ERROR: Timeout waiting for post title input" >&2
    exit 1
fi

# validate page directory
if [[ ! "${PAGE_DIR}" =~ ^(til|links|posts)$ ]]; then
    echo "ERROR: invalid page directory: ${PAGE_DIR}" >&2
    exit 1
fi

# ensure the target directory exists
if [[ ! -d "${HUGO_DIR}/content/${PAGE_DIR}" ]]; then
    echo "ERROR: target directory does not exist: ${HUGO_DIR}/content/${PAGE_DIR}" >&2
    exit 1
fi

# get tags
if [ "${ARG_TYPE}" != "link" ]
then
    echo -n "post tags (comma separated): "
    if ! read -r -t 60 TAGS; then
        echo "ERROR: Timeout waiting for tags input" >&2
        exit 1
    fi
    
    # validate tags
    TAGS=$(validate_input "$TAGS")
fi

#  title cleanup                    | non-printable
# FILE_TITLE=$(echo "${POST_TITLE}" | tr -dc "[:print:]" | \
#                # punctuation      | compress & replace spaces
#                 tr -d "[:punct:]" | tr -s "[:space:]" "-")

readonly TEMP_FILE=$(mktemp)
trap 'rm -f "${TEMP_FILE}"' EXIT

readonly POST_FILE="${HUGO_DIR}/content/${PAGE_DIR}/${DATESTAMP}.md"
echo "creating post file: ${POST_FILE}"
if [ -f "${POST_FILE}" ]; 
then
  echo "ERROR: POST FILE EXISTS - DEAL WITH THIS MANUALLY"
  echo "POST FILE: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
  exit 1
else
  sed -e "s/%%TITLE%%/${POST_TITLE//\//\\/}/g" \
    -e "s/%%WEATHER%%/${WEATHER:-}/g" \
    -e "s/%%LOCATION%%/${LOCATION:-}/g" \
    -e "s/%%YEAR%%/${YEAR}/g" \
    -e "s/%%TIMESTAMP%%/${TIMESTAMP}/g" \
    -e "s/%%TAGYEAR%%/${YEAR}/g" \
    -e "s/%%DATELINK%%/${DATELINK:-}/g" \
    -e "s/%%DATEFMT%%/${DATEFMT}/g" \
    -e "s/%%TAGS%%/${TAGS:-}/g" \
    -e "s/%%HOSTNAME%%/${HOSTNAME:-}/g" \
    < "${TEMPLATE}" > "${TEMP_FILE}"

  mv "${TEMP_FILE}" "${POST_FILE}"
  echo "editing: ${POST_FILE}"
  ${VISUAL} "${POST_FILE}"
fi
