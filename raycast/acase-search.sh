#!/bin/bash

# arista directory lookup
#
# see full documentation here: https://github.com/raycast/script-commands
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title acase
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 💼
# @raycast.author steve ulrich
# @raycast.authorURL https://github.com/sulrich
# @raycast.packageName sulrich-anet
# @raycast.argument1 { "type": "text", "placeholder": "TAC case #", "percentEncoded": true}

open "x-choosy://open/https://tac.aristanetworks.com/case/cv/view/${1}"

