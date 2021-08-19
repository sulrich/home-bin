#!/bin/bash

# run certbot with the renew option to make sure that we're never in a spot
# where we lose our certs and cause things to get borked.
# 
# put this some place root can access it and add it to the root crontab with
# the following entry
# 
# m h  dom mon dow   command
# 23  15  *   *   *   /...path_to.../cert-renew.sh

/usr/bin/certbot renew
systemctl restart nginx 
