#!/bin/zsh

DRIVE_TREE="/"
DRIVE_BACKUP="/Volumes/ZenBackup"

if [ -d ${DRIVE_BACKUP} ]
    then 
    echo "drive backup tree mounted: ${DRIVE_BACKUP}"
    /usr/bin/rsync -vaxE --ignore-errors --delete \
       $DEBUG_FLAGS $DRIVE_TREE $DRIVE_BACKUP
    else
    echo "drive backup tree not mounted"
fi

