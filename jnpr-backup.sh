#!/bin/bash

#if [ $# -eq 0 ]
#  then
#      echo "no backup host supplied"
#      cat <<EOF
#usage:
#   jnpr-backup.sh <dest-host>
#EOF
#      exit
#fi
#
#R_HOST=$1
#R_PATH="/home/sulrich/archives/juniper"

R_PATH="/Volumes/GoFlex/jnpr-backup"

# note - the source behavior here around the trailing slash
# RETAIN THE TRAILING SLASH ON THE SOURCE
#/usr/bin/rsync -avHS --delete-after ${HOME}/mail/                              \
#  sulrich@${R_HOST}:${R_PATH}/mail
#/usr/bin/rsync -avHS --delete-after ${HOME}/Desktop/                           \
#  sulrich@${R_HOST}:${R_PATH}/desktop
#/usr/bin/rsync -avHS --delete-after ${HOME}/Documents/work/                    \
#  sulrich@${R_HOST}:${R_PATH}/documents
#/usr/bin/rsync -avHS --delete-after ${HOME}/Downloads/                         \
#  sulrich@${R_HOST}:${R_PATH}/downloads
#/usr/bin/rsync -avHS --delete-after ${HOME}/src/                               \
#  sulrich@${R_HOST}:${R_PATH}/src

/usr/bin/rsync -avuzHS --delete-after ${HOME}/mail/            ${R_PATH}/mail
/usr/bin/rsync -avuzHS --delete-after ${HOME}/Desktop/         ${R_PATH}/desktop
/usr/bin/rsync -avuzHS --delete-after ${HOME}/Documents/work/  ${R_PATH}/documents
/usr/bin/rsync -avuzHS --delete-after ${HOME}/Downloads/       ${R_PATH}/downloads
/usr/bin/rsync -avuzHS --delete-after ${HOME}/src/             ${R_PATH}/src
/usr/bin/rsync -avuzHS --delete-after ${HOME}/tmp/             ${R_PATH}/tmp
