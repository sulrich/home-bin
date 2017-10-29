#!/usr/bin/env bash

# script automatically move phone pictures from our dropbox directories to
# the common backup directory


# destination directory for backup
export PHOTO_ARCH="/mnt/snuffles/media/GCP-MediaBackup/photo-archive"

# drop directories we'll be pulling from 
declare -a PHOTO_SRC=("/home/sulrich/Dropbox/Camera Uploads"
                      "/home/ktuzinski/Dropbox/Camera Uploads")

for S in "${PHOTO_SRC[@]}"
do
  echo "archiving from ${S} >> "
  echo "   ${PHOTO_ARCH}"
  echo "------------------------------------------------------------"
  cd "${S}"
  SAVEIFS=$IFS     # image filenames often have spaces, handle $IFS accordingly
  IFS=$(echo -en "\n\b")
  for F in *
  do
    echo "processing: ${F}"
    exiftool "-Directory<DateTimeOriginal" -d "${PHOTO_ARCH}/%Y/%m/%d" "${F}"
  done
  IFS=$SAVEIFS
done

