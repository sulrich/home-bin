#!/bin/zsh

# don't attempt to backup the entire system over the network - just the
# home directory

NET_TREE="/Users/sulrich"
NET_BACKUP="/Volumes/home_dirs/sulrich/zenpuppy-backup"

if [ -d ${NET_BACKUP} ]
    then 
    echo "net backup tree mounted: ${NET_BACKUP}"
    /usr/bin/rsync -av -E --ignore-errors --delete  \
	$DEBUG_FLAGS $NET_TREE $NET_BACKUP
    else
    echo "net backup tree not mounted!"
fi

