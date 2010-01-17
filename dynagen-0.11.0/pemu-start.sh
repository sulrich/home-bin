#!/bin/sh

# Set the directory you would like pemuwrapper to use for
# temp (the actual pemu binaries) here
TMP=/tmp

CWD=`pwd`
cd $TMP
python $CWD/pemuwrapper.py


