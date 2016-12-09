#!/bin/bash

#export WEBROOT="/home/shared/www/botwerks.net"
# 
# /home/sulrich/certbot/certbot-auto renew \
#   -a webroot --webroot-path=${WEBROOT}

/usr/bin/letsencrypt renew
systemctl restart nginx 
