#!/bin/bash
#
# runs fedifetcher within a container to fill in the missing discussion in my
# mastodon server.  this is something that plagues small standalone servers.
# cmonster crontab entry
# 0 * * * * ~/bin/fedifetcher.sh
# https://github.com/nanos/FediFetcher 
 
# server url
SERVER="botwerks.social"
# local filesystem cache
LOCAL_CACHE="${HOME}/prod/mastodon/fedifetcher"

# pull in my access token - loads ${ACCESS_TOKEN}
source "${HOME}/.credentials/fedifetcher.txt"

(flock -n 9 || exit 1;

  # ... commands executed under lock ...; 
  docker run --rm                    \
    -v ${LOCAL_CACHE}:/app/artifacts \
    ghcr.io/nanos/fedifetcher:latest \
    --access-token="${ACCESS_TOKEN}" \
    --server="${SERVER}"             \
    --home-timeline-length=300       \
    --max-followings=80              \
    --from-notifications=1

) 9>/tmp/fedifetcher.lock
