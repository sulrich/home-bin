#!/bin/bash

# declare -a RPATH=("/Volumes/JetDrive/jnpr-backup")
# "/Volumes/home/jnpr-backup"

# note - the source behavior here around the trailing slash is important.
# RETAIN THE TRAILING SLASH ON THE SOURCE

while [[ $# > 0 ]]
  do
  KEY="$1"

  case "${KEY}" in
    -r|--remote)
      RPATH=("${RPATH[@]}"
             "sulrich@dyn.botwerks.net:/mnt/snuffles/home/sulrich/jnpr-backup")
      echo "-- remote backup"
      echo "${RPATH[@]}"
      shift # get past this argument
      ;;
    -l|--local)
      RPATH=("${RPATH[@]}" "/Volumes/GoFlex/jnpr-backup"
             "sulrich@bert.local.:/mnt/snuffles/home/sulrich/jnpr-backup")
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
    /usr/bin/rsync -avuzHSq --delete-after "${HOME}/mail/"      "${R}/mail"
    /usr/bin/rsync -avuzHSq --delete-after "${HOME}/Desktop/"   "${R}/desktop"
    /usr/bin/rsync -avuzHSq --delete-after --exclude \
      'Virtual Machines.localized'                  \
      "${HOME}/Documents/"  "${R}/documents"
    /usr/bin/rsync -avuzHSq --delete-after "${HOME}/Downloads/" "${R}/downloads"
    /usr/bin/rsync -avuzHSq --delete-after "${HOME}/src/"       "${R}/src"
    /usr/bin/rsync -avuzHSq --delete-after "${HOME}/tmp/"       "${R}/tmp"
done

## local >> jetdrive
LOCAL_OPTS="-avuzHSq --delete-after"
JDEST="/Volumes/JetDrive/local_mirror"
echo "local backups"
echo "------------------------------------------------------------"
/usr/bin/rsync ${LOCAL_OPTS} "${HOME}/.gnupg/" "${JDEST}/gnupg"
/usr/bin/rsync ${LOCAL_OPTS} "${HOME}/.ssh/" "${JDEST}/ssh"
