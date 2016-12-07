#!/bin/bash

#export WEBROOT="/home/shared/www/botwerks.net"
# 
# /home/sulrich/certbot/certbot-auto renew \
#   -a webroot --webroot-path=${WEBROOT}

letsencrypt renew
systemctl restart nginx 
