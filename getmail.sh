#!/bin/bash

/usr/local/bin/setlock ${HOME}/.getmail/getmail.lck \
  /usr/local/bin/getmail --quiet &
