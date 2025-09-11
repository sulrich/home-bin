#!/bin/bash

# get the password for the restic repo.
RESTIC_PASSWORD_COMMAND="op read ${SULRICH_BKUP_1P}"
BREWFILE="${HOME}/iCloud/src/configs/${HOSTNAME}/Brewfile.txt"
BREWFILE_PREV="${HOME}/iCloud/src/configs/${HOSTNAME}/brewfile-prev.txt"
# reset in case getopts has been used previously in the script
OPTIND=1         

show_usage() {
  cat << EOF
usage: ${0##*/} [-hlrv]

    -h          display help and exit
    -l          local LAN backup (over ssh)
    -r          remote backup only (over 
    -v          verbose mode

IMPORTANT NOTE
the following environment variables must be set 
- SULRICH_BKUP_1P - the name of the 1password key to use for this host
- SULRICH_BKUP_RPATH - defines remote backup path
- SULRICH_BKUP_EXCLUDE - path to the host specific rsync exclusion file 

these are documented in the zshenv files.
EOF
}

if [ -z "${SULRICH_BKUP_RPATH}" ] || [ -z "${SULRICH_BKUP_EXCLUDE}" ];
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
    BKUP_HOST="snuffles"
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
echo "backup repository: ${RPATH}"

# make sure the icloud config directory exists.
mkdir -p "${HOME}/iCloud/src/configs/${HOSTNAME}" || { echo "failed to make icloud config dir" }
# get the latest list of ~/ symlinks
echo "snapshot symlinks"
ls -la "${HOME}" > "${HOME}/iCloud/src/configs/${HOSTNAME}/homedir-ls.txt"
# update installed brew apps list
echo "backing up brew list"
brew list --formula > "${HOME}/iCloud/src/configs/${HOSTNAME}/brew-list.txt"
brew list --cask    > "${HOME}/iCloud/src/configs/${HOSTNAME}/brew-cask-list.txt"
echo "moving old Brewfile"
mv "${BREWFILE}" "${BREWFILE_PREV}" || { echo "failed to move ${BREWFILE}" }
echo "dumping Brewfile"
brew bundle dump --file="${BREWFILE}"
echo "backing up crontab"
crontab -l > "${HOME}/iCloud/src/configs/${HOSTNAME}/crontab"
echo "capturing installed apps"
ls -1 "/Applications"         > "${HOME}/iCloud/src/configs/${HOSTNAME}/app-list.txt"
ls -1 "${HOME}/Applications" >> "${HOME}/iCloud/src/configs/${HOSTNAME}/app-list.txt"

restic -r "${RPATH}"                              \
  --exclude-file="${SULRICH_BKUP_EXCLUDE}"        \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  backup ~/
