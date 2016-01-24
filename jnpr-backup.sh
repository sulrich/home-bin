#!/bin/bash

declare -a RPATH=( 
  "/Volumes/GoFlex/jnpr-backup"
  "/Volumes/SlimDrive/jnpr-backup" 
)

# note - the source behavior here around the trailing slash is important. 
# RETAIN THE TRAILING SLASH ON THE SOURCE

for R in "${RPATH[@]}"
  do
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/mail/"            "${R}/mail"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Desktop/"         "${R}/desktop"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Documents/work/"  "${R}/documents"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Downloads/"       "${R}/downloads"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/src/"             "${R}/src"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/tmp/"             "${R}/tmp"
    /usr/bin/rsync -avuzHS --delete-after "${HOME}/Library/"         "${R}/library"
done

