#!/bin/zsh

# don't attempt to backup the entire system over the network - just the
# home directory

NET_TREE="/Users/sulrich/Pictures"
NET_BACKUP="/Volumes/media"

if [ -d ${NET_BACKUP} ]
then 
    echo "net backup tree mounted: ${NET_BACKUP}"
    /opt/local/bin/rsync -avE --ignore-errors --delete  \
	$DEBUG_FLAGS $NET_TREE $NET_BACKUP
else
    echo "net backup tree not mounted!"
fi

