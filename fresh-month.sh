#!/bin/bash

# roll over misc. logs and personal notes at the beginning of a new month. 
#
# crontab entry:
# 3 0 1 * *    $HOME/bin/fresh-month.sh
#

CURRENT_MONTH=$(date +%Y%m)
CONTENT_DIR="${HOME}/src/personal/botwerks-content"


fresh_notes() {
  # template with the relevant metadata for rendering in tools, etc.
  local NOTES_TEMPLATE="${HOME}/bin/templates/personal-notes.md"
  # directory where personal notes are stored
  local NOTES_DIR="${HOME}/.notes/deft"
  local NOTES_LINK="${HOME}/.monthly-notes.md"
  local MONTH_NOTES="${NOTES_DIR}/${CURRENT_MONTH}-personal-notes.md"

  sed "s/%%CURRENT_MONTH%%/${CURRENT_MONTH}/" < "${NOTES_TEMPLATE}" > "${MONTH_NOTES}"
  rm "${NOTES_LINK}"
  ln -s "${MONTH_NOTES}" "${NOTES_LINK}"
}

# montly blog links
fresh_bloglinks() {
  local TIMESTAMP="$(date +"%Y-%m-%d %H:%M:%S %z")"

  local LINKS_TEMPLATE="${HOME}/.home/templates/markdown/links-post.md"
  local MONTH_LINKS="${CONTENT_DIR}/post/${CURRENT_MONTH}-links.md"
  sed "s/%%CURRENT_MONTH%%/${CURRENT_MONTH}/" < "${LINKS_TEMPLATE}" |\
  sed "s/%%TIMESTAMP%%/${TIMESTAMP}/g" > "${MONTH_LINKS}"
}

fresh_bloglinks
