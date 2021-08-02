#!/bin/bash
# steve ulrich <sulrich@botwerks.org>
# 
# quick and dirty script to enable tunneling of various services to the home
# network when i'm wandering the earth.

# create a local alias for services which will not bind to localhost or
# potentially collide
/sbin/ifconfig lo0 alias 127.0.0.2 up

# use a custom ssh config to manage control elements, etc. 
ssh -N sulrich@home-tunnel -F "${HOME}/.home/tunnel-ssh-config"
