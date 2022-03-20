#!/bin/bash
## -*- mode: sh; fill-column: 78; comment-column: 50; tab-width: 2 -*-

trap cleanup SIGINT SIGTERM ERR EXIT


usage() {
    cat << EOF
usage: ${0##*/} [-h]

    -h          display help and exit
    XXX - list of args here

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

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

HOSTNAME=$(hostname)
source "${HOME}/.home/repo-lists/${HOSTNAME}"


# misc. git functions
function git-upstream-sync() {
  # for stuff that i am actively working on with others, work off of my fork and
  # update my $default_branch with the contents of the upstream. 

  # check for pending changes and break out of the update, this should be
  # resolved and updated manually
  git diff-index --quiet HEAD --
  if [ $? -eq 1 ]; then
    echo "ERROR: uncommitted changes ($(pwd))"
    cleanup
    exit 1
  fi

  # determine if the repo uses master/main as the default branch name
  local DEFAULT_BRANCH=$(git remote show upstream | grep 'HEAD branch' | awk '{print $NF}')
  echo "default branch: ${DEFAULT_BRANCH}"

  if [ -z "${DEFAULT_BRANCH}" ]; then
    echo ""
    echo "the upstream repo is undefined, you will need to add an upstream repo to track"
    echo "git remote add upstream <upstream-url-here>"
    echo ""
  else
    git checkout "${DEFAULT_BRANCH}"
    git fetch upstream
    git pull upstream "${DEFAULT_BRANCH}"
    git push origin "${DEFAULT_BRANCH}"
  fi
}

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}" || exit
  git pull
  echo ""
done

# mirror the following REPOs using a fetch/push bounce
# this assumes that internal mirror rmeote is named "ANET-MIRROR"
for REPO in "${MIRROR_LIST[@]}"; do
  echo "updating repo mirror: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}" || exit
  git fetch origin
  echo "pushing to internal mirror ${INTERNAL_REMOTE}"
  git push "${INTERNAL_REMOTE}"
  echo ""
done

for REPO in "${UPSTREAM_LIST[@]}"; do
  echo "syncing to upstream: ${REPO}"
  cd "${REPO}" || exit
  git-upstream-sync 
done

cleanup
