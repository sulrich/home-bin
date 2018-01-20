#!/usr/bin/env bash

# script automatically move phone pictures from our dropbox directories to
# the common backup directory


# destination directory for backup
export PHOTO_ARCH="/mnt/snuffles/media/GCP-MediaBackup/photo-archive"

# drop directories we'll be pulling from 
declare -a PHOTO_SRC=("/home/sulrich/Dropbox/Camera Uploads"
                      "/home/ktuzinski/Dropbox/Camera Uploads")


# move files into the archive directory based on their file name which includes
# the date.  follow the same directory structure as handled by the metadata
# driven move of the files.
manual_move () {
  FILE=$1
  # sample filename 2017-12-23 21.27.54.jpg
  REGEX="^(.*)-(.*)-(.*)[[:space:]]"
  if [[ "${FILE}" =~ ${REGEX} ]]; then
    FILE_YEAR=${BASH_REMATCH[1]}
    FILE_MONTH=${BASH_REMATCH[2]}
    FILE_DAY=${BASH_REMATCH[3]}
    DEST_PATH="${PHOTO_ARCH}/${FILE_YEAR}/${FILE_MONTH}/${FILE_DAY}"
    if [[ ! -d "${DEST_PATH}" ]]; then
      echo "destination directory doesn't exist"
      echo "creating directory: ${DEST_PATH}"
      mkdir "${DEST_PATH}"
    fi
    echo "moving: ${FILE} -> ${DEST_PATH}"
    mv "${FILE}"  "${DEST_PATH}"
  fi
}


for S in "${PHOTO_SRC[@]}"
do
  echo "archiving from ${S} >> "
  echo "   ${PHOTO_ARCH}"
  echo "-- exiftool processing"
  echo "------------------------------------------------------------"
  cd "${S}" || exit
  SAVEIFS=$IFS     # image filenames often have spaces, handle $IFS accordingly
  IFS=$(echo -en "\n\b")
  for F in *
  do
    echo "processing: ${F}"
    exiftool "-Directory<DateTimeOriginal" -d "${PHOTO_ARCH}/%Y/%m/%d" "${F}"
  done
  IFS=$SAVEIFS
done


for S in "${PHOTO_SRC[@]}"
do
  echo "archiving from ${S} >> "
  echo "   ${PHOTO_ARCH}"
  echo "-- file name processing (non-metadata driven)"
  echo "------------------------------------------------------------"
  cd "${S}" || exit
  SAVEIFS=$IFS     # image filenames often have spaces, handle $IFS accordingly
  IFS=$(echo -en "\n\b")
  for F in *
  do
    echo "processing: ${F}"
    manual_move "$F"
  done
  IFS=$SAVEIFS
done
