#!/bin/bash

# script to generate the weekly log files and create the necessary symlink to
# the desktop to make life simple.  to be run out of cron on monday @ 0000

DESKTOP_FILE="${HOME}/Desktop/worklog-current.org"
HEAD_TEMPLATE="${HOME}/.notes/juniper/weekly-notes/templates/head.org"
LOG_DIR="${HOME}/.notes/juniper/weekly-notes"
# NB: this date stuff only works on the mac
CURRENT_WEEK=$(date -v "-Mon" +"%Y%m%d")
CURRENT_YEAR=$(date -v "-Mon" +"%Y")
# you can chain these date calcs together - who knew?
LAST_WEEK=$(date -v "-Mon" -v-1w +"%Y%m%d")
LAST_YEAR=$(date -v "-Mon" -v-1w +"%Y")


if [[ ! -d "${LOG_DIR}/${YEAR}" ]];
then
  echo "log directory doesn't exist: ${LOG_DIR}/${YEAR}"
  mkdir "${LOG_DIR}/${YEAR}"
  exit
fi


rm ${DESKTOP_FILE}
cat ${HEAD_TEMPLATE} | sed "s/%%CURRENT_WEEK%%/${CURRENT_WEEK}/" \
  > /tmp/worklog-head.tmp
cat /tmp/worklog-head.tmp "${LOG_DIR}/${LAST_YEAR}/${LAST_WEEK}-notes.org" \
  > "${LOG_DIR}/${CURRENT_YEAR}/${CURRENT_WEEK}-notes.org" 
ln -s "${LOG_DIR}/${CURRENT_YEAR}/${CURRENT_WEEK}-notes.org" ${DESKTOP_FILE}
