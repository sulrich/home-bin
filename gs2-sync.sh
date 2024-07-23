#!/bin/bash

EXCLUDE_LIST="*.img,*.vmdk,*.qcow2,*.iso"
REMOTE_PATH="/home/sulrich/"
LOCAL_PATH="${HOME}/src/gserver2"

rsync -avz  --exclude-from="${HOME}/.home/rsync-excludes.txt" --max-size=100m \
  -d --delete-excluded \
  sulrich@google-server2:${REMOTE_PATH} "${LOCAL_PATH}"
