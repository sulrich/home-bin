#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

declare -a REPO_LIST=(
  "${HOME}/src/openconfig/public"
  "${HOME}/src/openconfig/goyang"
  "${HOME}/src/yang"
  "${HOME}/src/grpc"
  "${HOME}/src/grpc-go"

)

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd ${REPO}
  git pull
done
