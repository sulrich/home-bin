#!/bin/bash

# get the password for the restic repo.
RESTIC_PASSWORD_COMMAND="/usr/local/bin/op get item ${SULRICH_BKUP_1P} --fields password"
BREWFILE="${HOME}/iCloud/src/configs/${HOST}/Brewfile.txt"
# reset in case getopts has been used previously in the script
OPTIND=1         

show_usage() {
  cat << EOF
usage: ${0##*/} [-hlrv]

    -h          display help and exit
    -l          local backup (direct attached drive) and remote (over ssh) 
                ssh backup will used bonjour appropriate hostname(s).
    -r          remote backup only (over ssh)
    -v          verbose mode

IMPORTANT NOTE
the following environment variables must be set 
- SULRICH_BKUP_RPATH - defines remote backup path
- SULRICH_BKUP_EXCLUDE - path to the host specific rsync exclusion file 

these are documented in the zshenv files.
EOF
}

if [ -z "${SULRICH_BKUP_RPATH}" ] || [ -z "${SULRICH_BKUP_EXCLUDE}"  ];
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
    echo "specify remote or locale execution"
    show_usage
    exit 1
  esac
done

shift "$((OPTIND-1))"
[ "$1" = "--" ] && shift

RPATH="sftp:${USER}@${BKUP_HOST}:${SULRICH_BKUP_RPATH}"

# get the latest list of ~/ symlinks
echo "snapshot symlinks"
ls -la "${HOME}" > "${HOME}/iCloud/src/configs/${HOSTNAME}/homedir-ls.txt"
# update installed brew apps list
echo "backing up brew list"
brew list --formula > "${HOME}/iCloud/src/configs/${HOSTNAME}/brew-list.txt"
brew list --cask    > "${HOME}/iCloud/src/configs/${HOSTNAME}/brew-cask-list.txt"
brew bundle dump --file="${BREWFILE}"
# dump my crontab
echo "backing up crontab"
crontab -l > "${HOME}/iCloud/src/configs/${HOSTNAME}/crontab"
echo "backing up ssh/config"
cp "${HOME}/.ssh/config" "${HOME}/iCloud/src/configs/${HOSTNAME}-ssh-config"
# echo list /Applications
echo "capturing installed apps"
ls -1 "/Applications"         > "${HOME}/iCloud/src/configs/${HOSTNAME}/app-list.txt"
ls -1 "${HOME}/Applications" >> "${HOME}/iCloud/src/configs/${HOSTNAME}/app-list.txt"

restic -r "${RPATH}"                              \
  --exclude-file="${SULRICH_BKUP_EXCLUDE}"        \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  backup ~/
