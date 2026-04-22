#!/bin/bash

PATH=/usr/local/bin:/usr/bin:/bin
GITEA_USER="sulrich"
GITEA_CONTAINER="gitea"
BACKUP_DIR="${HOME}/prod/gitea/tmp"
KEEP_BACKUPS=7

if [ ! -d "${HOME}/prod/gitea" ]
then
  echo "target environment not found - aborting"
  exit 1
fi

echo "generating backup ..."
# ref: https://docs.gitea.com/administration/backup-and-restore
docker exec -u "${GITEA_USER}" -w /tmp \
  $(docker ps -qf 'name=^gitea$') bash -c '/usr/local/bin/gitea dump -c /data/gitea/conf/app.ini'

# note that gitea dump embeds the timestamp into the file name.  this is
# expressed in terms of secs since the epoch as opposed to something human
# readable.  used `date -d @XXXXXX` to get something readable here.

# prune old backups, keeping only the N most recent
# mapfile (bash builtin, not available in zsh) reads lines from the process
# substitution into the array "backups", -t strips trailing newlines from each
# element. ls -t sorts newest-first, so backups[0] is the most recent file.
mapfile -t backups < <(ls -t "${BACKUP_DIR}"/gitea-dump-*.zip 2>/dev/null)
if (( ${#backups[@]} > KEEP_BACKUPS )); then
  echo "pruning $((${#backups[@]} - KEEP_BACKUPS)) old backup(s) ..."
  printf '%s\n' "${backups[@]:${KEEP_BACKUPS}}" | xargs rm --
fi
