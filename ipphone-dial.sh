#!/bin/sh
#
RCFILE=$HOME/.ipphone
PREFIX='91'

#if [ a$1 = a ]
#then
#    printf '\n\nUsage: dial <dial string>\n\n'
#    exit
#fi

if [ ! -f $HOME/.ipphone ] 
then
    printf 'phone IP address (press settings-3-6 to find out): ' 
    read aIP
    printf 'phone username: '
    read aUser
    printf 'phone password (not echoed): '
    stty -echo
    read aPass
    stty echo
    echo #!/bin/sh >$RCFILE
    echo IPPHONE_CREDENTIALS=$aUser:$aPass >>$RCFILE
    echo IPPHONE_ADDRESS=$aIP >>$RCFILE
    chmod 600 $RCFILE
fi

. $HOME/.ipphone

#
PHONENUM=`pbpaste | sed 's/[^[:alnum:]]//g'`;
DIGITS=$PREFIX$PHONENUM

echo Dialing $DIGITS...

curl --user $IPPHONE_CREDENTIALS -d 'XML=%3CCiscoIPPhoneExecute%3E%3CExecuteItem+URL%3D%27Dial%3A'$DIGITS'%27%2F%3E%3C%2FCiscoIPPhoneExecute%3E&B1=Submit' http://$IPPHONE_ADDRESS/CGI/Execute 


