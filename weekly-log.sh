#!/bin/bash

# script to generate the weekly log files and create the necessary symlink to
# the desktop to make life simple.  to be run out of cron on monday @ 0003
#
# crontab entry:
# 3 0 * * mon    $HOME/bin/weekly-log.sh
#

# current week's notes are found here - this is a symlink
DESKTOP_FILE="${HOME}/Desktop/worklog-current.md"
LATEST_NOTES="${HOME}/.notes/worklog-current.md"

# header w/relevant metadata for rendering in tools, etc.
HEAD_TEMPLATE="${HOME}/.home/templates/markdown/weekly-head.md"

# directory where weekly notes are stored
LOG_DIR="${HOME}/.notes"

# NB: this date stuff only works on the mac.  if you want this to render more
# consistently on linux, etc. using gdate you need to use the -d "string"
# structure. e.g.: date -d "last Monday" +%Y%m%d 
CURRENT_WEEK=$(date -v "-Mon" +"%Y%m%d")
CURRENT_YEAR=$(date -v "-Mon" +"%Y")
# you can chain these date calcs together - who knew?
# NB: there doesn't seem to be a gdate equivalent. 
# LAST_WEEK=$(date -v "-Mon" -v-1w +"%Y%m%d")
# LAST_YEAR=$(date -v "-Mon" -v-1w +"%Y")

if [ ! -d "${LOG_DIR}/${CURRENT_YEAR}" ];
then
  echo "log directory doesn't exist: ${LOG_DIR}/${CURRENT_YEAR}"
  mkdir -p "${LOG_DIR}/${CURRENT_YEAR}"
  exit
fi

rm "${DESKTOP_FILE}"
sed "s/%%CURRENT_WEEK%%/${CURRENT_WEEK}/" < "${HEAD_TEMPLATE}"        \
  > "${LOG_DIR}/${CURRENT_YEAR}/${CURRENT_WEEK}-weekly-notes.md"
ln -s "${LOG_DIR}/${CURRENT_YEAR}/${CURRENT_WEEK}-weekly-notes.md" "${DESKTOP_FILE}"
ln -s "${LOG_DIR}/${CURRENT_YEAR}/${CURRENT_WEEK}-weekly-notes.md" "${LATEST_NOTES}"
