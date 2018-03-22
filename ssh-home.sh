#!/bin/bash
#
# script to provide ssh tunnel to internal hosts in a single shot with the
# associated port mappings to access internal web interfaces.
#
# list of internal hosts with mappings:
#
# 10.0.0.241 - virl server
# 10.0.0.243 - snuffles admin interface
# 10.0.0.245 - cmonster vnc instance
# 10.0.0.251 - ubiquity web management console
#

ssh -L 4443:10.0.0.1:443    \
    -L 8080:10.0.0.241:80   \
    -L 5000:10.0.0.243:5000 \
    -L 6901:10.0.0.245:5901 \
    -L 8443:10.0.0.251:8443 \
    dyn.botwerks.net
