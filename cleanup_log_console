#!/bin/sh
#
# Clean up the nulls, ^h sequences and DOS style EOL's sometimes
# present in saved IOS console log files.
#
# By dash
#
for FILE in $*
do
    TMPFILE=`mktemp /private/tmp/$FILE.XXXXXX` || exit 1
    col -xb < $FILE                              | \
	sed 's/\r\n/\n/g'                        | \
	sed 's/!{100,}/!!!\[...\]/g'             | \
	sed 's/#{100,}/###\[...\]/g'             > $TMPFILE
    mv $TMPFILE $FILE
done
