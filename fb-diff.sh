#!/bin/zsh

data_file="${HOME}/bin/data/fb-friends.txt"
log="${HOME}/bin/data/fb-log.txt"
tmp_file="/tmp/cur-fb-list.tmp"
fbcmd="${HOME}/bin/fbcmd"
date=`date +%Y%m%d`


${fbcmd} friends > ${tmp_file}
echo "${date} start ------------------------------" >> ${log}
diff ${data_file} ${tmp_file} >> ${log}
mv   ${tmp_file}  ${data_file}
echo "${date} end   ------------------------------" >> ${log}



