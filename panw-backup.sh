#!/bin/bash

declare -a RPATH=("/Volumes/GoFlex/panw-backup")
# "/Volumes/home/panw-backup"

# note - the source behavior here around the trailing slash is important.
# RETAIN THE TRAILING SLASH ON THE SOURCE

while [[ $# > 0 ]]
  do
  KEY="$1"

  case "${KEY}" in
    -r|--remote)
      RPATH=("sulrich@dyn.botwerks.net:/mnt/snuffles/home/sulrich/panw-backup")
      echo "-- remote backup"
      echo "${RPATH[@]}"
      shift # get past this argument
      ;;
    -l|--local)
      RPATH=("${RPATH[@]}" "sulrich@bert.local.:/mnt/snuffles/home/sulrich/panw-backup")
      echo "-- local backup"
      echo "${RPATH[@]}"
      shift # get past this argument
      ;;
    *)
      echo "no options specified"
      ;;
  esac
  shift # past argument or value
done

for R in "${RPATH[@]}"
  do
    echo "backing up to ${R}"
    echo "------------------------------------------------------------"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/mail/"        "${R}/mail"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Desktop/"     "${R}/desktop"
    /usr/bin/rsync -avuzHS --delete-after --exclude 'Virtual Machines.localized' \
        "${HOME}/Documents/"  "${R}/documents"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Downloads/"   "${R}/downloads"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/src/"         "${R}/src"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/tmp/"         "${R}/tmp"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Library/"     "${R}/library"
done

