#!/bin/sh
#
RCFILE=$HOME/.vonage
PREFIX='1'

#if [ a$1 = a ]
#then
#    printf '\n\nUsage: dial <dial string>\n\n'
#    exit
#fi

if [ ! -f $HOME/.vonage ] 
then
    printf 'phone number: ' 
    read aPhoneNum
    printf 'phone username: '
    read aUser
    printf 'phone password (not echoed): '
    stty -echo
    read aPass
    stty echo
    echo #!/bin/sh >$RCFILE
    echo VONAGE_USERNAME=$aUser    >>$RCFILE
    echo VONAGE_PASSWORD=$aPass    >>$RCFILE
    echo VONAGE_NUMBER=$aPhoneNum  >>$RCFILE
    chmod 600 $RCFILE
fi

. $HOME/.vonage

#
PHONENUM=`pbpaste | sed 's/[^[:alnum:]]//g'`;
DIGITS=$PREFIX$PHONENUM

echo Dialing $DIGITS...

DIAL_URL="https://secure.click2callu.com/tpcc/makecall?username=$VONAGE_USERNAME&password=$VONAGE_PASSWORD&fromnumber=$VONAGE_NUMBER&tonumber=$DIGITS"

curl $DIAL_URL
# echo $DIAL_URL