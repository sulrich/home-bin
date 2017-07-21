#!/bin/bash
NEWFILE=/tmp/mutt_bak_`basename $1`
rm -f ${NEWFILE} 
cp $1 ${NEWFILE} 1>/dev/null 2>&1
open ${NEWFILE}
