#!/bin/bash
DOMAIN="dyn.botwerks.net"
ZNC_BASE="/home/sulrich/prod/znc"
 
[[ $RENEWED_LINEAGE != "/etc/letsencrypt/live/${DOMAIN}" ]] && exit 0
echo "updating certs"
cat /etc/letsencrypt/live/${DOMAIN}/{privkey,fullchain}.pem > "${ZNC_BASE}/znc.pem"
