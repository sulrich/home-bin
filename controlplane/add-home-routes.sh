#!/bin/bash

# the work VPN will provide covering routes for networks that i'd like to be
# able to reach from the home network via the site-to-site VPN. this script is
# to be triggered by controlplane when it detects the location.

## zenith: add releveant routes when at zenith
zenith() {
  sudo route add -net 10.10.0.0/24 10.0.0.1
}


## lanesboro: add releveant routes when at lanesboro
lanesboro() {
  sudo route add -net 10.0.0.0/24 10.10.0.1
}

help() {
  cat << EOF
available functions:
EOF
  sed -n "s/^##//p" "$0" | column -t -s ":" | sed -e "s/^/ /"
}

if [[ $# -lt 1 ]]; then
  help
  exit
fi

case $1 in
  *)
    # shift positional arguments so that arg 2 becomes arg 1, etc.
    CMD=$1
    shift 1
    ${CMD} ${@} || help
    ;;
esac

# keep this - it lets you run the various functions in this script
#"$@"

