#!/bin/bash

# feed the ia writer machine with the reasonable template

NOTE_DIR="${HOME}/.notes"
TODAY=$(date +"%Y%m%d")
NOTE_TEMPLATE="${HOME}/.home/templates/markdown/daily-notes.md"

NOTE_FILE="${NOTE_DIR}/${TODAY}.md"

sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" >> "${NOTE_FILE}"
