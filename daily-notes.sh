#!/bin/bash

# when you run this from cron/launchd, things aren't necessarly happy.
export PATH="/opt/homebrew/bin:$PATH"

# feed the ia writer machine with the reasonable template
YEAR=$(date +"%Y")
TODAY=$(date +"%Y%m%d")
CREATE_DATE=$(date +"%Y-%m-%d")
NOTE_TEMPLATE="${HOME}/.home/templates/markdown/daily-notes.md"
NOTE_DIR="${HOME}/.notes/${YEAR}"

PERSONAL_CLASS="personal"
PERSONAL_EMAIL="sulrich@botwerks.org"
PERSONAL_FILE="${NOTE_DIR}/${TODAY}-personal-notes.md"
PERSONAL_TAGS="#personal #diary #notes"
WORK_CLASS="work"
WORK_EMAIL="sulrich@arista.com"
WORK_FILE="${NOTE_DIR}/${YEAR}/${TODAY}-work-notes.md"
WORK_TAGS="#arista #work"

if [ ! -d ${NOTE_DIR} ]
then
  mkdir -p ${NOTE_DIR}
fi

get_weather() {
  # the getCoreLocationData shortcut is the replacement for the old CLI program
  # to glean this info. 
  LOCATION_DATA=$(eval '/usr/bin/shortcuts run getCoreLocationData | cat')
  CITY=$(jq -r '.city' <<<"${LOCATION_DATA}")
  STATE=$(jq -r '.state' <<<"${LOCATION_DATA}")
  LOCATION="${CITY}, ${STATE}"
  CITY=$(echo ${LOCATION} | tr -d ' ')

  # WEATHER=$(curl -s "http://wttr.in/${CITY}?format=+%c(%C)+%t(%f)+")
  WEATHER="fill this in yourself steve!"
  LOCATION=$(echo "${LOCATION}" | tr '[:upper:]' '[:lower:]')
}

## work: emits the work-day notes template
write_work() {
  sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" |\
      sed "s/%%CREATE_DATE%%/${CREATE_DATE}/g"     |\
      sed "s/%%TAGS%%/${WORK_TAGS}/g"              |\
      sed "s/%%CLASS%%/${WORK_CLASS}/g"            |\
      sed "s/%%EMAIL%%/${WORK_EMAIL}/g" >> "${WORK_FILE}"
}

## personal: emits the personal notes template
write_personal(){
  sed "s/%%TODAY%%/${TODAY}/" < "${NOTE_TEMPLATE}" |\
      sed "s/%%CREATE_DATE%%/${CREATE_DATE}/g"     |\
      sed "s/%%TAGS%%/${PERSONAL_TAGS}/g"          |\
      sed "s/%%CLASS%%/${PERSONAL_CLASS}/g"        |\
      sed "s/%%EMAIL%%/${PERSONAL_EMAIL}/g" >> "${PERSONAL_FILE}"
}


## both: helper to write both templates to disk
write_both() {
  write_work
  write_personal
}

# anything that has ## at the front of the line will be used as input.
## help: details the available functions in this script
help() {
  usage
  echo "available functions:"
  sed -n 's/^##//p' $0 | column -t -s ':' | sed -e 's/^/ /'
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT

    # script cleanup here, tmp files, etc.
}

if [[ $# -lt 1 ]]; then
  help
  exit
fi

case $1 in
  personal)
    write_personal
    exit
    ;;
  work)
    write_work
    exit
    ;;
  both)
    write_both
    exit
    ;;
  *)
    help
    ;;
esac
