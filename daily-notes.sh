#!/bin/bash

# feed the ia writer machine with the reasonable template
NOTE_DIR="${HOME}/.notes"
TODAY=$(date +"%Y%m%d")
CREATE_DATE=$(date +"%Y-%m-%d")
NOTE_TEMPLATE="${HOME}/.home/templates/markdown/daily-notes.md"

NOTE_FILE="${NOTE_DIR}/${TODAY}-misc-notes.md"

# the getCoreLocationData shortcut is the replacement for the old CLI program
# to glean this info. 
LOCATION_DATA=$(eval '/usr/bin/shortcuts run getCoreLocationData | cat')
CITY=$(jq -r '.city' <<<"${LOCATION_DATA}")
STATE=$(jq -r '.state' <<<"${LOCATION_DATA}")
LOCATION="${CITY}, ${STATE}"
CITY=$(echo ${LOCATION} | tr -d ' ')

WEATHER=$(curl -s "http://wttr.in/${CITY}?format=+%c(%C)+%t(%f)+")
LOCATION=$(echo "${LOCATION}" | tr '[:upper:]' '[:lower:]')

sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" |\
    sed "s/%%WEATHER%%/${WEATHER}/g"             |\
    sed "s/%%CREATE_DATE%%/${CREATE_DATE}/g"     |\
    # sed "s/%%LOCATION%%/${LOCATION}/g" 
    sed "s/%%LOCATION%%/${LOCATION}/g" >> "${NOTE_FILE}"
