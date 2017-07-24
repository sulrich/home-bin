#!/bin/bash

PROX=$(networksetup -getsocksfirewallproxy "wi-fi" | grep "No")

# connect to botsocks proxy (ernie.botwerks.net)
# this assumes that the relevant ssh configuration is in place

if [ -n "${PROX}" ]; then
  echo "ssh to botsocks"
  ssh -fNq botsocks
  echo "... configuring SOCKS proxy"
  sudo networksetup -setsocksfirewallproxy "wi-fi" localhost 8080
  sudo networksetup -setsocksfirewallproxystate "wi-fi" on
else
  echo "... removing SOCKS proxy configuration "
  sudo networksetup -setsocksfirewallproxystate "wi-fi" off
  sudo networksetup -setsocksfirewallproxy "wi-fi" "" ""
  ssh -O stop botsocks
fi
