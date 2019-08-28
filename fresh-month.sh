#!/bin/bash

# roll over misc. logs and personal notes at the beginning of a new month. 
#
# crontab entry:
# 3 0 1 * *    $HOME/bin/fresh-month.sh
#


CURRENT_MONTH=$(date +%Y%m)

# template with the relevant metadata for rendering in tools, etc.
NOTES_TEMPLATE="${HOME}/bin/templates/personal-notes.md"

# directory where personal notes are stored
NOTES_DIR="${HOME}/.notes/deft"

NOTES_LINK="${HOME}/.monthly-notes.md"
MONTH_NOTES="${NOTES_DIR}/${CURRENT_MONTH}-personal-notes.md"

sed "s/%%CURRENT_MONTH%%/${CURRENT_MONTH}/" < "${NOTES_TEMPLATE}" > "${MONTH_NOTES}"
rm "${NOTES_LINK}"
ln -s "${MONTH_NOTES}" "${NOTES_LINK}"
