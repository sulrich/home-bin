#!/bin/bash

# list of local directories to be moved into the destination archive_dir.
# THE TRAILING SLASH ON SOURCE DIRECTORIES IS IMPORTANT 
declare -a RPATH=(
  "/Volumes/media/Music/"
)

# destination directory/filesystem
ARCHIVE_DIR="/Volumes/MusicBackup"

# check to see if archive file system exists
if [ ! -d "${ARCHIVE_DIR}" ];
then
  echo "ERROR - archive destination not mounted (${ARCHIVE_DIR})"
  exit 1
fi


DTS=$(date +"%Y%m%d-%H%M")
BACKUP_LOG_FILE="${HOME}/tmp/backup-${DTS}.log"

for R in "${RPATH[@]}"
do
  if [ ! -d "${R}" ];
  then
    echo "ERROR - archive source not available (${R})"
    exit 1
  fi
  P=$(echo "${R}" | cut -d "/" -f 4)
  ARCH_PATH="${ARCHIVE_DIR}/${P}"
  # echo "${R} - ${P} - ${ARCH_PATH} - ${BACKUP_LOG_FILE}"
  rsync -avuzSq --ignore-errors --delete-after \
        --log-file="${BACKUP_LOG_FILE}" "${R}" "${ARCH_PATH}"
done

