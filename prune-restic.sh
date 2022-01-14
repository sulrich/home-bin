#!/bin/bash

# get the password for the restic repo.
RESTIC_PASSWORD_COMMAND="/usr/local/bin/op get item ${SULRICH_BKUP_1P} --fields password"
# reset in case getopts has been used previously in the script
OPTIND=1         

# this is a restic policy string that defines the time period to keep snapshots
# around.  this will be used by the keep-duration flag in the pruning process
# 
# from the docs: 
# --keep-within duration keep all snapshots which have been made within the
# duration of the latest snapshot. duration needs to be a number of years,
# months, days, and hours, e.g. 2y5m7d3h will keep all snapshots made in the two
# years, five months, seven days, and three hours before the latest snapshots
# 
# note: restic uses "natural" time definitions.
BKUP_DURATION="60d"

show_usage() {
  cat << EOF
usage: ${0##*/} [-hlrv]

    -h          display help and exit
    -l          local restic instance (over ssh) 
                ssh backup will used bonjour appropriate hostname(s).
    -r          remote restic instance(over ssh)
    -v          verbose mode

IMPORTANT NOTE
the following environment variables must be set 
- SULRICH_BKUP_1P - the name of the 1password key to use for this host
- SULRICH_BKUP_RPATH - defines remote backup path

these are documented in the zshenv files.
EOF
}

if [ -z "${SULRICH_BKUP_RPATH}" ] || [ -z "${SULRICH_BKUP_1P}"  ];
then
  echo "required environment vars missing!"
  show_usage
  exit 1
fi

if [ $# -eq 0 ];
then
  echo "no options specified"
  show_usage
  exit 1
fi

while getopts "hlr" OPT;
do
  case "${OPT}" in
  h)
    show_usage
    exit 0
    ;;
  l)
    echo "-- local backup"
    BKUP_HOST="snuffles.local."
    echo "-- host: ${BKUP_HOST}"
    echo "-- path: ${SULRICH_BKUP_RPATH}"
    ;;
  r)
    echo "-- remote backup"
    BKUP_HOST="snuffles-remote"
    echo "-- host: ${BKUP_HOST}"
    echo "-- path: ${SULRICH_BKUP_RPATH}"
    ;;
  *)
    # echo usage
    echo "specify remote or local execution"
    show_usage
    exit 1
  esac
done

shift "$((OPTIND-1))"
[ "$1" = "--" ] && shift

RPATH="sftp:${USER}@${BKUP_HOST}:${SULRICH_BKUP_RPATH}"

# apply policy
echo "current snapshots"
restic -r "${RPATH}"                              \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  snapshots

echo "forgetting old files (older than: ${BKUP_DURATION}) ..."
restic -r "${RPATH}"                              \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  forget --keep-within "${BKUP_DURATION}"  

echo "updated snapshots"
restic -r "${RPATH}"                              \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  snapshots

echo "repacking snapshots ... (this may take a while)"
restic -r "${RPATH}"                              \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  prune  

echo "checking snapshot integrity"
restic -r "${RPATH}"                              \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  check 

