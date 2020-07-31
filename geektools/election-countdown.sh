#!/bin/bash

PATH=/usr/local/bin:${PATH}

D1=$(gdate -d "3 nov" +%s)
D2=$(gdate +%s)
echo $(( (D1 - D2) / 86400 )) 'days to vote' | /usr/local/bin/figlet
