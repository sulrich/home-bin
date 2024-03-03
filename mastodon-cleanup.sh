#!/usr/bin/env bash
#
# this is to be run only on cmonster.botwerks.net
#
# the container image is specific to this installation.

/usr/bin/docker exec -it mstdn-web tootctl media usage
/usr/bin/docker exec -it mstdn-web tootctl media remove --days=30
/usr/bin/docker exec -it mstdn-web tootctl preview_cards remove --days=30
/usr/bin/docker exec -it mstdn-web tootctl media usage

