#!/bin/bash

# Raycast Script Command Template
#
# Duplicate this file and remove ".template." from the filename to get started.
# See full documentation here: https://github.com/raycast/script-commands
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title set system volume 30%
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🔊
# @raycast.packageName Raycast Scripts

osascript -e "set Volume 3"
echo "system volume set to 30%"

