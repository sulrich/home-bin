#!/bin/bash

# @raycast.schemaVersion 1
# @raycast.argument1 { "type": "text", "placeholder": "emoji" }
# @raycast.argument2 { "type": "text", "placeholder": "status" }
# @raycast.mode fullOutput
# @raycast.title omg lol status
# @raycast.icon 😍
# @raycast.packageName omg-lol-status

# Documentation:
# 
# @raycast.description updates omg.lol status
# @raycast.author sulrich@botwerks.org
# @raycast.authorURL https://botwerks.net
#

OMG_USERNAME="sulrich"
OMG_API_KEY=$(op read "op://Private/api.omg.lol/credential")

curl -s --location --request POST                           \
    --header "Authorization: Bearer ${OMG_API_KEY}"         \
    --data '{"emoji": "'"${1}"'", "content": "'"${2}"'"}'   \
    "https://api.omg.lol/address/${OMG_USERNAME}/statuses/" 
