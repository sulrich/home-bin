#!/usr/bin/env bash
# -*- mode: sh; fill-column: 78; comment-column: 50; tab-width: 2 -*-

trap cleanup SIGINT SIGTERM ERR EXIT

## work: set the work git config params
function work() {
  check_gitdir
  source "${HOME}/.dotfiles/git/repo-config"
  set_config "${REPO_COMMANDS[@]}"
}

## personal: set the personal git config params
function personal() {
  check_gitdir
  source "${HOME}/.home/git/repo-config"
  set_config "${REPO_COMMANDS[@]}"

}

function check_gitdir() {
  # configure git in the current repo for work or personal use.
  IS_GITDIR=$(git rev-parse --is-inside-work-tree)
  if [[ $IS_GITDIR != "true" ]]; then
    # this is not a git repository - error out
    echo ""
    echo "ERROR: this is not a git repo"
    exit 1
  fi 
}

function set_config() {
  REPO_COMMANDS=$1
  # run config commands
  for CMD in "${REPO_COMMANDS[@]}"; 
  do 
    echo "${CMD}"
    eval "${CMD}"
  done
}

function usage() {
    cat << EOF
usage: ${0##*/} [-h]
  set-local-git-config.sh [work|personal]
    -h          display help and exit
EOF
}

# anything that has ## at the front of the line will be used as input.
## help: details the available functions in this script
help() {
  usage
  echo "available functions:"
  sed -n 's/^##//p' $0 | column -t -s ':' | sed -e 's/^/ /'
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # script cleanup here, tmp files, etc.
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
