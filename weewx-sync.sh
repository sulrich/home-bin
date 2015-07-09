#!/bin/bash

rsync -avz --delete-after sulrich@weewx-pi.local.:/home/weewx/ ${HOME}/weewx-backup

