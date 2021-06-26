#!/bin/bash

# quick backup script using restic

# TODO
# - check to make sure that the right volume is mounted, if not, prompt or
#   automount. 
# - make sure that the repo is initialized
# - figure out what needs to be done to correctly initialize the op client
# 

REPO_PATH="/Volumes/home/archive/backups/krusty-backup"
RESTIC_PASSWORD_COMMAND="/usr/local/bin/op get item 'restic: krusty' --fields password"

restic -r "${REPO_PATH}"                          \
  --exclude-file="${SULRICH_BKUP_EXCLUDE}"        \
  --password-command="${RESTIC_PASSWORD_COMMAND}" \
  backup ~/
