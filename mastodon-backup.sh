#!/usr/bin/env bash

# steps
# - dump the associated databases to a location where they can be used for
#   generating tarballs. 
# - generate the necessary tarballs
#   - the tarballs should be date ordered
# - move the tarballs to the NAS

# source the key environment elements 
source "/home/sulrich/prod/mastodon/.env.production"

BKUP_TEMP="/home/sulrich/prod/mastodon/tmp"
BKUP_DEST="/mnt/snuffles/home/sulrich/archive/mastodon"
BKUP_DATE=$(date +"%Y%m%d")

# backup the postgres database
echo "backing up postgres db"
docker exec mstdn-postgres /bin/bash                  \
 -c "/usr/local/bin/pg_dump -U ${DB_USER} ${DB_NAME}" \
 | gzip -9 > "${BKUP_TEMP}/${DB_NAME}-postgres.sql.gz"

# backup redis
echo "backing up redis dump"
sudo cp "/home/sulrich/prod/mastodon/redis/dump.rdb" "${BKUP_TEMP}/redis-dump.rdb"

# tar ball generation
echo "generating tar archive: ${BKUP_DATE}-mastodon.tar.gz"
sudo tar -czvf - ${BKUP_TEMP}/* > "${BKUP_DEST}/${BKUP_DATE}-mastodon.tar.gz"



