#!/bin/zsh

curl_dest="${HOME}/downloads/chromium-latest.zip"

build_url="http://build.chromium.org/buildbot/snapshots/chromium-rel-mac"
build_id=`/usr/bin/curl -s ${build_url}/LATEST`
latest_url="${build_url}/${build_id}/chrome-mac.zip"

echo "${latest_url} -> ${curl_dest}"
/usr/bin/curl -s -o ${curl_dest} ${latest_url}
