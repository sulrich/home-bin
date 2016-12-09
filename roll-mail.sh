#!/bin/bash
# -*- mode: sh; fill-column: 78; comment-column: 50; tab-width: 2 -*-

# roll the current directory full of maildirs over to the archives.  this makes
# some assumptions as to the directory layout as specified in the $ARCH_DIR
# variable

LAST_MO_YEAR=$(date -v -1m +%Y)
#SRC_DIR=$(basename "${PWD}") # to be used in event mail gets restructured
SRC_DIR="root-dir"
ARCH_DIR="${HOME}/Documents/archives/mail/${LAST_MO_YEAR}/${SRC_DIR}"

echo "rolling over ${PWD} -> $ARCH_DIR"

for M in  $(basename "${PWD}/*") ; do
  if [[ "${M}" =~ ^inbox|^outbox ]];
  then
    echo "skipping: ${M}";
    continue;
  fi 
  ${HOME}/bin/split-maildirs.pl --keep_recent \
         --arch_dir="${ARCH_DIR}" --src_dir="${PWD}" "${M}";
  echo "${M}";
done
