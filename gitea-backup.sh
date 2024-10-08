#!/bin/bash

GITEA_USER="sulrich"
GITEA_CONTAINER="gitea"

if [ ! -d "${HOME}/prod/gitea" ]
then
  echo "target environment not found - aborting"
  exit 1
fi 


echo "generating backup ..."
# ref: https://docs.gitea.com/administration/backup-and-restore
docker exec -u "${GITEA_USER}" -it -w /tmp \
  $(docker ps -qf 'name=^gitea$') bash -c '/usr/local/bin/gitea dump -c /data/gitea/conf/app.ini'
