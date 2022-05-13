#!/bin/bash

# where my unduz at?
declare -a UNDO_DIRS=(
  "${HOME}/.config/nvim/undo"
  "${HOME}/.vim/undo"
)


for UNDO_DIR in "${UNDO_DIRS[@]}"
do
  for UNDO_FILE in "${UNDO_DIR}"/* 
  do
    [ -e "${UNDO_FILE}" ] || continue
    echo "undo: ${UNDO_FILE}"
    REAL_FILE=$(basename "${UNDO_FILE}" | sed 's:%:/:g')
    echo "real: ${REAL_FILE}"
    [ -e "${REAL_FILE}" ] || rm -i  -- "${UNDO_FILE}"
  done
done
