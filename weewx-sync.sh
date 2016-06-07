#!/bin/bash

source ${HOME}/.keychain/${HOSTNAME}-sh 
rsync -avz --delete-after sulrich@weewx-pi.local.:/home/weewx/ ${HOME}/weewx-backup

