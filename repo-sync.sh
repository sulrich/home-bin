#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

HOSTNAME=$(hostname)
source "${HOME}/.home/repo-lists/${HOSTNAME}"

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
