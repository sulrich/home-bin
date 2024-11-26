#!/usr/bin/env bash
## -*- mode: sh; fill-column: 78; comment-column: 50; tab-width: 2 -*-

trap cleanup SIGINT SIGTERM ERR EXIT


usage() {
    cat << EOF
usage: ${0##*/} [-h]

    -h          display help and exit
    XXX - list of args here

EOF
}



# use rsync to sync a collection of file hierarchies.  to be used with care
function main {
  FROM_HOST=$1
  TO_HOST=$2

  source "${HOME}/.home/repo-lists/sync-list.txt"

  if [ "${FROM_HOST}" == "${HOSTNAME}" ]; then
    FROM_HOST=""
  else
    FROM_HOST="${FROM_HOST}:"
  fi

  if [ "${TO_HOST}" == "${HOSTNAME}" ]; then
    TO_HOST=""
  else
    TO_HOST="${TO_HOST}:"
  fi

  local EXCLUDE_LIST=".venv"

  # for each repo in the sync list, munge the path appropriately and do an
  # rsync. be verbose
  echo "from: ${FROM_HOST} to: ${TO_HOST}"
  for ITEM in "${SYNC_LIST[@]}"; do 
    echo "syncing: ${ITEM}"
    FROM_PATH="${FROM_HOST}${ITEM}/"
    TO_PATH="${TO_HOST}${ITEM}"
    echo "from: ${FROM_PATH} ${TO_PATH}"
    rsync -aP --exclude="${EXCLUDE_LIST}" ${FROM_PATH} ${TO_PATH}
  done
}


# anything that has ## at the front of the line will be used as input.
## help: details the available functions in this script
help() {
  usage
  echo "available functions:"
  sed -n 's/^##//p' $0 | column -t -s ':' | sed -e 's/^/ /'
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT

    # script cleanup here, tmp files, etc.
}

if [[ $# -lt 2 ]]; then
  help
  exit
fi

case $1 in
  *)
    # shift positional arguments so that arg 2 becomes arg 1, etc.
    # shift 1
    main ${@} || help
    ;;
esac
