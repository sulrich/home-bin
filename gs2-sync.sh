#!/bin/bash

EXCLUDE_LIST="*.img,*.vmdk,*.qcow2,*.iso"
REMOTE_PATH="/home/arista/"
LOCAL_PATH="${HOME}/src/gserver2"

rsync -avz                                             \
  --exclude='*.img'                                    \
  --exclude='*.iso'                                    \
  --exclude='*.pid'                                    \
  --exclude='*.qcow'                                   \
  --exclude='*.qcow2'                                  \
  --exclude='*.swi'                                    \
  --exclude='*.swi'                                    \
  --exclude='*.vmdk'                                   \
  --exclude='.cache/'                                  \
  --exclude='.pyenv/'                                  \
  --exclude='go/'                                      \
  --max-size=100m                                      \
  arista@google-server2:${REMOTE_PATH} "${LOCAL_PATH}"
