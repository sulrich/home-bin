#!/bin/bash
#
# clean up the nulls, ^h sequences and dos style eol's sometimes
# present in saved ios console log files.
#
for FILE in $*
do
    TMPFILE=`mktemp /private/tmp/$FILE.XXXXXX` || exit 1
    col -xb < $FILE                        | \
	sed 's/\r\n/\n/g'                        | \
	sed 's/!{100,}/!!!\[...\]/g'             | \
	sed 's/#{100,}/###\[...\]/g'             > $TMPFILE
    mv $TMPFILE $FILE
done
