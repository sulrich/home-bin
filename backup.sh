#!/bin/bash

# declare -a RPATH=("/Volumes/JetDrive/arista-backup")
# "/Volumes/home/arista-backup"

# local home directory files that i want to have backed up to my jetdrive. in
# case shit goes sideways.
declare -a DOTFILES=("gnupg" "ssh" "aws" "ipython" "matplotlib" "perlbrew"
                     "docker" "npm" "config" "matplotlib" "cpanm" "gem"
                     "credentials" "vim")

# note - the source behavior here around the trailing slash is important.
# RETAIN THE TRAILING SLASH ON THE SOURCE

DTS=$(date +"%Y%m%d-%H%M")
BACKUP_LOG_FILE="${HOME}/tmp/backup-${DTS}.log"

USB_DRIVE="TeraBacktyl"  # the name of the local backup USB drive to use
# this should be an array to provide the right arg processing later.
declare -a RSYNC_OPTS=("-avuzHSq" "--delete-after" "--log-file=${BACKUP_LOG_FILE}")
OPTIND=1         # reset in case getopts has been used previously in the script

HOST=$(hostname)

# display usage info
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

SULRICH_BKUP_RPATH - defines remote backup path
SULRICH_BKUP_EXCLUDE - path to the host specific rsync exclusion file 
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

while getopts "hlrv" OPT;
do
  case "${OPT}" in
  h)
    show_usage
    exit 0
    ;;
  l)
    RPATH=("sulrich@abby.local.:${SULRICH_BKUP_RPATH}")
    echo "-- local backup"
    echo "-- path: ${RPATH[*]}"
    ;;
  r)
    RPATH=("sulrich@dyn.botwerks.net:${SULRICH_BKUP_RPATH}")
    echo "-- remote backup"
    echo "-- path: ${RPATH[*]}"
    ;;
  v)
    echo "-- verbose mode"
    # rip out the -q flag, -q suppresses non-ERROR output
    declare -a RSYNC_OPTS=( "${RSYNC_OPTS[@]/q/}" )
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

# get the latest list of ~/ symlinks
echo "snapshot symlinks"
ls -la "${HOME}" > "${HOME}/iCloud/src/configs/${HOST}/homedir-ls.txt"
# update installed brew apps list
echo "backing up brew list"
brew list       > "${HOME}/iCloud/src/configs/${HOST}/brew-list.txt"
brew cask list >> "${HOME}/iCloud/src/configs/${HOST}/brew-list.txt"
# dump my crontab
echo "backing up crontab"
crontab -l > "${HOME}/iCloud/src/configs/${HOST}/crontab"
# echo list /Applications
echo "capturing installed apps"
ls -1 "/Applications"         > "${HOME}/iCloud/src/configs/${HOST}/app-list.txt"
ls -1 "${HOME}/Applications" >> "${HOME}/iCloud/src/configs/${HOST}/app-list.txt"

echo "rsync flags: ${RSYNC_OPTS[*]}"
for R in "${RPATH[@]}"
do
  echo "backup dst: ${R}"
  echo " excluding: ${SULRICH_BKUP_EXCLUDE}"
  echo "------------------------------------------------------------"
  # note that the RSYNC_OPTS below should _not_ be doublequoted, rsync barfs on
  # that.
  /usr/bin/rsync ${RSYNC_OPTS[*]}                         \
                 --exclude-from="${SULRICH_BKUP_EXCLUDE}" \
                   "${HOME}/"  "${R}"
done

# ## local >> jetdrive
# JDEST="/Volumes/JetDrive/local_mirror"
# echo "local dotfile backups"
# echo "------------------------------------------------------------"
#
# for L in "${DOTFILES[@]}"
# do
#   echo  "- ${L}"
#   /usr/bin/rsync ${RSYNC_OPTS[*]} "${HOME}/.${L}/"  "${JDEST}/${L}"
# done
