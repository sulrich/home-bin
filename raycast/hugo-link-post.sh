#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title hugo link post
# @raycast.mode fullOutput
# @raycast.packageName sulrich-blog

# Optional parameters:
# @raycast.icon 🔗
# @raycast.argument1 { "type": "text", "placeholder": "Post Title", "optional": true }

# Documentation:
# @raycast.description Creates a Hugo link post from highlighted text and current URL
# @raycast.author steve ulrich
# @raycast.authorURL https://github.com/sulrich

# set up logging
mkdir -p "${HOME}/tmp"
LOG_FILE="${HOME}/tmp/raycast_hugo_link.log"
exec 1>>"${LOG_FILE}" 2>&1

# set environment variables
TEMPLATE="${HOME}/.home/templates/markdown/blog-links.md"
HUGO_DIR="${HOME}/src/personal/botwerks-site"
VISUAL="vimr"

# Get the URL and selected text from Chrome
get_chrome_url() {
  osascript <<EOF
    tell application "Google Chrome"
      try
        set currentURL to URL of active tab of front window
        return currentURL
      on error
        return "error"
      end try
    end tell
EOF
}

get_chrome_selection() {
  osascript <<EOF
    tell application "Google Chrome"
      try
        set selectedText to (execute active tab of front window javascript "window.getSelection().toString();")
        return selectedText
      on error
        return ""
      end try
    end tell
EOF
}

get_chrome_title() {
  osascript <<EOF
    tell application "Google Chrome"
      try
        set pageTitle to title of active tab of front window
        return pageTitle
      on error
        return ""
      end try
    end tell
EOF
}

# get url, selected text, and title
URL=$(get_chrome_url)
if [[ "$URL" == "error" ]]; then
  echo "could not access chrome. make sure chrome is running with an active tab."
  exit 1
fi

HIGHLIGHTED_TEXT=$(get_chrome_selection)
if [[ -z "$HIGHLIGHTED_TEXT" ]]; then
  echo "no text selected in browser. creating link post without blockquote."
fi

# Set post title
POST_TITLE=$1
if [[ -z "$POST_TITLE" ]]; then
  chrome_title=$(get_chrome_title)
  
  if [[ -n "$chrome_title" ]]; then
    POST_TITLE="$chrome_title"
  elif [[ -n "$HIGHLIGHTED_TEXT" ]]; then
    POST_TITLE=$(echo "$HIGHLIGHTED_TEXT" | head -n 1 | cut -c 1-50)
  else
    POST_TITLE="Link to $(echo $URL | cut -d'/' -f3)"
  fi
  
  if [[ ${#POST_TITLE} -eq 50 ]]; then
    POST_TITLE="${POST_TITLE}..."
  fi
fi

# format dates
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %z")
DATESTAMP=$(date +"%Y%m%d-%H%M%S")
YEAR=$(date +"%Y")
DATELINK=$(date +"%d-%b-%Y")

# create post file
PAGE_DIR="links"
POST_FILE="${HUGO_DIR}/content/${PAGE_DIR}/${DATESTAMP}.md"

# make sure target directory exists
mkdir -p "${HUGO_DIR}/content/${PAGE_DIR}"

# check if post file already exists
if [ -f "${POST_FILE}" ]; then
  echo "ERROR: post file already exists: ${POST_FILE}"
  exit 1
fi

# get template
if [[ ! -f "${TEMPLATE}" ]]; then
  echo "ERROR: template file not found: ${TEMPLATE}"
  exit 1
fi

# create temp file for editing
TEMP_FILE=$(mktemp)
trap 'rm -f "${TEMP_FILE}"' EXIT

# Apply template and replacements
sed -e "s/%%TITLE%%/${POST_TITLE//\//\\/}/g" \
    -e "s/%%TIMESTAMP%%/${TIMESTAMP}/g" \
    -e "s/%%TAGYEAR%%/${YEAR}/g" \
    -e "s/%%DATELINK%%/${DATELINK}/g" \
    -e "s/%%HOSTNAME%%//g" \
    < "${TEMPLATE}" > "${TEMP_FILE}"

# add link content
CONTENT_FILE=$(mktemp)
trap 'rm -f "${CONTENT_FILE}" "${TEMP_FILE}"' EXIT

# create the content to insert
if [[ -n "$HIGHLIGHTED_TEXT" ]]; then
  echo "[${POST_TITLE}](${URL})" > "${CONTENT_FILE}"
  echo "" >> "${CONTENT_FILE}"
  echo "> ${HIGHLIGHTED_TEXT}" >> "${CONTENT_FILE}"
  echo "" >> "${CONTENT_FILE}"
else
  echo "[${POST_TITLE}](${URL})" > "${CONTENT_FILE}"
  echo "" >> "${CONTENT_FILE}"
fi

# insert the content before the marker
awk -v content="$(cat ${CONTENT_FILE})" '
  /<!-- LINK_CONTENT -->/ { print content }
  { print }
' "${TEMP_FILE}" > "${TEMP_FILE}.new"
mv "${TEMP_FILE}.new" "${TEMP_FILE}"

# move to final location
mv "${TEMP_FILE}" "${POST_FILE}"

# open in editor
${VISUAL} "${POST_FILE}" || echo "ERROR: Failed to open editor"

echo "created link post: ${POST_FILE}"

# clean up log file if successful
exit_status=$?
if [ $exit_status -eq 0 ]; then
  rm -f "${LOG_FILE}"
fi
exit $exit_status
