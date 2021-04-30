#!/bin/bash

print_usage() {
  cat <<EOF
tmux-win.sh <tmux-session-name> <inventory-file>

overview

  this script is meant to be used with the ansible-inventory.yml file generated
  from the containerlab tool.  it will create a new tmux session, munge the
  hostname for the virtual routers to set the window title, create the window
  within the newly created session and pre-stage the ssh session for
  connectivity to the device.  

EOF
}

main() {
  local SESSION_NAME=${1} # tmux session name 
  local INVENTORY=${2}    # ansible inventory file
  
  # get the lab hostnames from the inventory file
  HOSTMAP=( $(shyaml keys all.children.ceos.hosts < "${INVENTORY}") )

  tmux new-session -s "${SESSION_NAME}" -d
  for WIND in "${HOSTMAP[@]}";
  do
    A_HOST=$(shyaml get-value \
      "all.children.ceos.hosts.${WIND}.ansible_host" < "${INVENTORY}")
    # use the internal replacement funcs and push into array
    NAMEPARTS=(${WIND//-/ })  
    # grab the last element of the split function
    # W_NAME=${NAMEPARTS[-1]}  # if you're on a modern bash
    # if on macos
    W_NAME=${NAMEPARTS[${#NAMEPARTS[@]}-1]}
    echo "creating: ${SESSION_NAME}:${W_NAME}"
    tmux new-window -n "${W_NAME}" -t "${SESSION_NAME}"
    tmux send-keys -t "${SESSION_NAME}:${W_NAME}" "ssh ${A_HOST}"
  done
}

if [ "$#" -ne 2 ]; then
  print_usage
  exit
fi
main $1 $2
