#!/bin/bash

show_usage() {
  cat <<EOF
    usage: ${0##*/} (start|stop)

    start - start the global protect agent
    stop  - stop the global protect agent
EOF
}


if [ $# -eq 0 ]; then
  echo "no action specified"
  show_usage
  exit 1
fi 

case "$1" in 
  start)
    echo -n "starting globalprotect..."
    launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangpa.plist
    launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangps.plist
    echo "done!"
    ;;
  stop)
    echo -n "stopping globalprotect..."
    launchctl remove com.paloaltonetworks.gp.pangps
    launchctl remove com.paloaltonetworks.gp.pangpa
    echo "done!"
    ;;
  *)
    show_usage
    exit 1
    ;;
esac



