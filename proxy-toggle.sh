#!/bin/bash

PROX=$(networksetup -getsocksfirewallproxy "wi-fi" | grep "No")
echo "${PROX}"

# connect to botsocks proxy (ernie.botwerks.net)
# this assumes that the relevant ssh configuration is in place
# 
# note: it would seem that one should also yank the associated
# setsocksfirewallproxy configuration back to null, but that seems to cause
# other problems and cannot be deterministically ordered at this time. bleh.

if [ -n "${PROX}" ]; then
  echo "ssh to botsocks"
  ssh -fNq botsocks
  echo "... configuring SOCKS proxy"
  sudo networksetup -setsocksfirewallproxy wi-fi localhost 8080
  sudo networksetup -setsocksfirewallproxystate wi-fi on
  networksetup -getsocksfirewallproxy "wi-fi"
else
  echo "... disabling SOCKS proxy configuration"
  sudo networksetup -setsocksfirewallproxystate wi-fi off
  ssh -O stop botsocks
  networksetup -getsocksfirewallproxy "wi-fi"
fi
