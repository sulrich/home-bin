#!/bin/bash

# arista directory lookup
#
# see full documentation here: https://github.com/raycast/script-commands
#
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title adir
# @raycast.mode silent
#
# Optional parameters:
# @raycast.icon 🤖
# @raycast.author steve ulrich
# @raycast.authorURL https://github.com/sulrich
# @raycast.packageName sulrich-anet
# @raycast.argument1 { "type": "text", "placeholder": "query", "percentEncoded": true}

open "x-choosy://open/https://intranet.arista.com/search-results?searchword=${1}"

