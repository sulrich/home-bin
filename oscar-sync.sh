#!/bin/bash

declare -a RPATH=(
  "/usr/local/etc/"
  "/usr/local/www/"
)

export ARCHIVEDIR="/mnt/snuffles/home/sulrich/archive/oscar-backup"

for R in "${RPATH[@]}"
  do
    P=$(echo ${R} | cut -d "/" -f 4)
    ARCH_PATH="${ARCHIVEDIR}/${P}"
    #echo "${R} - ${P} - ${ARCH_PATH}"
    rsync -a --ignore-errors --no-links --delete-after\
      sulrich@oscar.botwerks.net:${R} ${ARCH_PATH}
done

