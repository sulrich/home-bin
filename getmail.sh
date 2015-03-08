#!/bin/bash

/usr/local/bin/setlock -n ${HOME}/.getmail/getmail.lck \
  /usr/local/bin/getmail --quiet &
