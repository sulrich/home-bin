#!/bin/zsh

SRC_TREE="/Users/sulrich/Pictures"
NET_BACKUP="/Volumes/media"
LOCAL_BACKUP="/Volumes/TeraMonster/media"

if [ -d ${NET_BACKUP} ]
then 
    echo "net backup tree mounted: ${NET_BACKUP}"
    echo "sync photo collection: ${NET_BACKUP}"
    /opt/local/bin/rsync -avE --ignore-errors --delete  \
	$DEBUG_FLAGS $SRC_TREE $NET_BACKUP
else
    echo "net backup tree not mounted!"
fi


if [ -d ${LOCAL_BACKUP} ]
then 
    echo "local backup tree mounted: ${LOCAL_BACKUP}"
    echo "sync photo collection: ${LOCAL_BACKUP}"
    /opt/local/bin/rsync -avE --ignore-errors --delete  \
	${DEBUG_FLAGS} ${SRC_TREE} ${LOCAL_BACKUP}
else
    echo "net backup tree not mounted!"
fi
