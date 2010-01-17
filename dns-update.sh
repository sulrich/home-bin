#!/bin/zsh

  key_file="${HOME}/bin/keys/Keepers.ddns.botwerks.net.+157+28228.key" 
update_file="/tmp/host-dns-update.txt"
   ext_host="eepers.ddns.botwerks.net"
        ttl="60"
     ip_url="http://www.botwerks.org/cgi-bin/printenv"
     ipaddr=`/usr/bin/curl -s ${ip_url} | grep REMOTE_ADDR | awk '{print $3}'`

     echo ${ipaddr}
echo "server 208.42.63.173"                          > ${update_file}
echo "update delete ${ext_host} A"                  >> ${update_file}
echo "update add ${ext_host} ${ttl} IN A ${ipaddr}" >> ${update_file}
echo ""                                             >> ${update_file}

/usr/bin/nsupdate -k ${key_file} -d ${update_file}

