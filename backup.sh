#!/bin/bash

# declare -a RPATH=("/Volumes/JetDrive/jnpr-backup")
# "/Volumes/home/jnpr-backup"

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
    # RPATH=("${RPATH[@]}" "/Volumes/${USB_DRIVE}/jnpr-backup"
    RPATH=( "/Volumes/${USB_DRIVE}/jnpr-backup"
           "sulrich@bert.local.:/mnt/snuffles/home/sulrich/jnpr-backup")
    echo "-- local backup"
    echo "-- path: ${RPATH[*]}"
    ;;
  r)
    RPATH=("sulrich@dyn.botwerks.net:/mnt/snuffles/home/sulrich/jnpr-backup")
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
ls -la "${HOME}" > "${HOME}/Dropbox/personal/configs/homedir-ls.txt"
# update installed brew apps list
echo "backing up brew list"
brew list       > "${HOME}/Dropbox/personal/configs/brew-list.txt"
brew cask list >> "${HOME}/Dropbox/personal/configs/brew-list.txt"
# dump my crontab
echo "backing up crontab"
crontab -l > "${HOME}/Dropbox/personal/configs/crontab"


echo "rsync flags: ${RSYNC_OPTS[*]}"
for R in "${RPATH[@]}"
do
  echo "backing up to ${R}"
  echo "------------------------------------------------------------"
  # note that the RSYNC_OPTS below should _not_ be doublequoted, rsync barfs on
  # that.
  /usr/bin/rsync ${RSYNC_OPTS[*]}                                     \
                 --exclude-from="${HOME}/bin/backup-exclude-list.txt" \
                   "${HOME}/"  "${R}"
done

## local >> jetdrive
JDEST="/Volumes/JetDrive/local_mirror"
echo "local dotfile backups"
echo "------------------------------------------------------------"

for L in "${DOTFILES[@]}"
do
  echo  "- ${L}"
  /usr/bin/rsync ${RSYNC_OPTS[*]} "${HOME}/.${L}/"  "${JDEST}/${L}"
done
