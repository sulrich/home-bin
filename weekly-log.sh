#!/bin/bash

# script to generate the weekly log files and create the necessary symlink to
# the desktop to make life simple.  to be run out of cron on monday @ 0000

DESKTOP_FILE="${HOME}/Desktop/worklog-current.org"
HEAD_TEMPLATE="${HOME}/.notes/juniper/weekly-notes/templates/head.org"
LOG_DIR="${HOME}/.notes/juniper/weekly-notes"
LAST_WEEK=$(date -v-1w +"%Y%m%d")
CURRENT_WEEK=$(date +"%Y%m%d")
YEAR=$(date +"%Y")

rm ${DESKTOP_FILE}
cat ${HEAD_TEMPLATE} | sed "s/%%CURRENT_WEEK%%/${CURRENT_WEEK}/" \
  > /tmp/worklog-head.tmp
cat /tmp/worklog-head.tmp "${LOG_DIR}/${YEAR}/${LAST_WEEK}-weekly_notes.org" \
  > "${LOG_DIR}/${YEAR}/${CURRENT_WEEK}-weekly_notes.org" 
ln -s "${LOG_DIR}/${YEAR}/${CURRENT_WEEK}-weekly_notes.org" ${DESKTOP_FILE}
