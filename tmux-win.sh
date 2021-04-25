#!/bin/bash

SESSION_NAME=$1 # tmux session
INVENTORY=$2    # ansible inventory file

# get the lab hostnames from the inventory file
HOSTMAP=( $(shyaml keys all.children.ceos.hosts < "${INVENTORY}") )

tmux new-session -s "${SESSION_NAME}" -d
for WIND in "${HOSTMAP[@]}";
do
  A_HOST=$(shyaml get-value \
    "all.children.ceos.hosts.${WIND}.ansible_host" < "${INVENTORY}")
  tmux new-window -n "${WIND}" -t "${SESSION_NAME}"
  tmux send-keys -t "${SESSION_NAME}:${WIND}" "ssh ${A_HOST}"
done

