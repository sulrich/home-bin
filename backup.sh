#!/bin/bash

# declare -a RPATH=("/Volumes/JetDrive/jnpr-backup")
# "/Volumes/home/jnpr-backup"

# note - the source behavior here around the trailing slash is important.
# RETAIN THE TRAILING SLASH ON THE SOURCE

RSYNC_OPTS="-avuzHSq --delete-after"
OPTIND=1         # reset in case getopts has been used previously in the script

# display usage info
show_usage() {
  cat << EOF
usage: ${0##*/} [-hlrv]

    -h          display help and exit
    -l          local backup (direct attached drive) and remote (over ssh)
    -r          remote backup only (over ssh)
    -v          verbose mode

EOF
}

if [ $# -eq 0 ];
then
  echo "no options specified"
  show_usage
  exit 1
fi

while getopts "hlrv" OPT;
do
  case "${OPT}" in
  h)
    show_usage
    exit 0
    ;;
  l)
    RPATH=("${RPATH[@]}" "/Volumes/DookieDrive/jnpr-backup"
           "sulrich@bert.local.:/mnt/snuffles/home/sulrich/jnpr-backup")
    echo "-- local backup"
    echo "-- path: ${RPATH[@]}"
    ;;
  r)
    RPATH=("${RPATH[@]}"
           "sulrich@dyn.botwerks.net:/mnt/snuffles/home/sulrich/jnpr-backup")
    echo "-- remote backup"
    echo "path: ${RPATH[@]}"
    ;;
  v)
    echo "-- verbose mode"
    # rip out the -q flag - -q suppresses non-ERROR output
    RSYNC_OPTS=$(echo ${RSYNC_OPTS} | sed 's/q//')
    ;;
  esac
done

shift "$((OPTIND-1))"
[ "$1" = "--" ] && shift

# get the latest list of ~/ symlinks
echo "snapshot symlinks"
ls -la ${HOME} > ${HOME}/Dropbox/homedir-ls.txt
# update installed brew apps list
echo "backing up brew list"
brew list > ${HOME}/Dropbox/brew-list.txt
# dump my crontab
echo "backing up crontab"
crontab -l > ${HOME}/Dropbox/crontab


echo "rsync flags: ${RSYNC_OPTS}"
for R in "${RPATH[@]}"
  do
    echo "backing up to ${R}"
    echo "------------------------------------------------------------"
    /usr/bin/rsync ${RSYNC_OPTS} --exclude           \
      'Documents/Virtual Machines.localized'         \
      'Library/Caches/Google/Chrome'                 \
      "${HOME}/"  "${R}"
done

## local >> jetdrive
JDEST="/Volumes/JetDrive/local_mirror"
echo "local backups"
echo "------------------------------------------------------------"
/usr/bin/rsync ${RSYNC_OPTS} "${HOME}/.gnupg/" "${JDEST}/gnupg"
/usr/bin/rsync ${RSYNC_OPTS} "${HOME}/.ssh/"   "${JDEST}/ssh"
/usr/bin/rsync ${RSYNC_OPTS} "${HOME}/.aws/"   "${JDEST}/aws"

