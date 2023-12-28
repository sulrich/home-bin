#!/bin/bash

# when you run this from cron/launchd, things aren't necessarly happy.
export PATH="/opt/homebrew/bin:$PATH"

# feed the ia writer machine with the reasonable template
NOTE_DIR="${HOME}/.notes"
TODAY=$(date +"%Y%m%d")
CREATE_DATE=$(date +"%Y-%m-%d")
NOTE_TEMPLATE="${HOME}/.home/templates/markdown/daily-notes.md"

WORK_FILE="${NOTE_DIR}/${TODAY}-work-notes.md"
WORK_TAGS="#arista #work"
WORK_CLASS="work"
PERSONAL_FILE="${NOTE_DIR}/${TODAY}-personal-notes.md"
PERSONAL_TAGS="#personal #diary #notes"
PERSONAL_CLASS="personal"

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
    sed "s/%%TAGS%%/${WORK_TAGS}/g"              |\
    sed "s/%%CLASS%%/${WORK_CLASS}/g"            |\
    sed "s/%%LOCATION%%/${LOCATION}/g" >> "${WORK_FILE}"

sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" |\
    sed "s/%%WEATHER%%/${WEATHER}/g"             |\
    sed "s/%%CREATE_DATE%%/${CREATE_DATE}/g"     |\
    sed "s/%%TAGS%%/${PERSONAL_TAGS}/g"          |\
    sed "s/%%CLASS%%/${PERSONAL_CLASS}/g"        |\
    sed "s/%%LOCATION%%/${LOCATION}/g" >> "${PERSONAL_FILE}"
