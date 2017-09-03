#!/bin/bash


MUTT_STR="set smtp_pass=\"%%PASSWORD%%\"     #SMTP password"
IMAP_STR="%%PASSWORD%%"

CREDS_DIR="${HOME}/.credentials"
MUTT_FILE="${CREDS_DIR}/mutt-passwords.gpg"
IMAP_FILE="${CREDS_DIR}/offlineimap-passwd.gpg"

echo -n "enter new password: "
read PASSWORD

echo ${MUTT_STR} | sed "s/%%PASSWORD%%/${PASSWORD}/" | gpg -e \
       -r sulrich@juniper.net -o ${MUTT_FILE}
echo ${IMAP_STR} | sed "s/%%PASSWORD%%/${PASSWORD}/" | gpg -e \
       -r sulrich@juniper.net -o ${IMAP_FILE}

