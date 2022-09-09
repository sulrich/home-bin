#!/bin/bash

# feed the ia writer machine with the reasonable template

NOTE_DIR="${HOME}/.notes"
TODAY=$(date +"%Y%m%d")
CREATE_DATE=$(date +"%Y-%m-%d")
NOTE_TEMPLATE="${HOME}/.home/templates/markdown/daily-notes.md"

NOTE_FILE="${NOTE_DIR}/${TODAY}.md"

LOCATION=$("/opt/homebrew/bin/CoreLocationCLI" --format "%locality, %administrativeArea")
CITY=$("/opt/homebrew/bin/CoreLocationCLI" --format "%latitude,%longitude")

WEATHER=$(curl -s "http://wttr.in/~${CITY}?format=+%c(%C)+%t")
LOCATION=$(echo "${LOCATION}" | tr '[:upper:]' '[:lower:]')

sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" |\
    sed "s/%%WEATHER%%/${WEATHER}/g"             |\
    sed "s/%%CREATE_DATE%%/${CREATE_DATE}/g"     |\
    sed "s/%%LOCATION%%/${LOCATION}/g" >> "${NOTE_FILE}"
