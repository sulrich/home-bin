#!/bin/bash

if [ $# -eq 0 ]
  then
      echo "no target host supplied"
      cat <<EOF
usage:
   sync-ltop.sh <dest-host>
EOF
      exit
fi

R_HOST=$1
R_PATH="/Users/sulrich"

# note - the source behavior here around the trailing slash
# RETAIN THE TRAILING SLASH ON THE SOURCE

/usr/bin/rsync -avHS --delete-after ${HOME}/mail/                              \
  sulrich@${R_HOST}:${R_PATH}/mail
/usr/bin/rsync -avHS --delete-after ${HOME}/Desktop/                           \
  sulrich@${R_HOST}:${R_PATH}/Desktop
/usr/bin/rsync -avHS --delete-after ${HOME}/Documents/work/                    \
  sulrich@${R_HOST}:${R_PATH}/Documents/work
/usr/bin/rsync -avHS --delete-after ${HOME}/Downloads/                         \
  sulrich@${R_HOST}:${R_PATH}/Downloads
/usr/bin/rsync -avHS --delete-after ${HOME}/src/                               \
  sulrich@${R_HOST}:${R_PATH}/src
