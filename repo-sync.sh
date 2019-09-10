#!/bin/bash

# every morning there are repos that i want to make sure I'm aware of updates to.
# just update this list of repos with the remote contents
#
# NOTE - *do not* use this for repos that i'm doing development on myself.
# these should be kept fresh through the usual channels.

declare -a REPO_LIST=(
  # openconfig repos
  "${HOME}/src/openconfig/public" 
  "${HOME}/src/openconfig/gnmi"
  "${HOME}/src/openconfig/gnoi"
  "${HOME}/src/openconfig/goyang"
  "${HOME}/src/openconfig/oc-pyang"
  "${HOME}/src/openconfig/gnmitest"
  "${HOME}/src/openconfig/gribi"
  "${HOME}/src/openconfig/reference"
  "${HOME}/src/openconfig/ygot"
  "${HOME}/src/yang"

  # P4 repos
  "${HOME}/src/p4/tutorials"
  "${HOME}/src/p4/PI"
  "${HOME}/src/p4/p4-applications"
  "${HOME}/src/p4/p4-spec"

  # arista repos - these have been deprecated for g* protocol work
  # "${HOME}/src/arista/gnmitest_common"
  # "${HOME}/src/arista/gnmitest_arista"
 
  # google repos
  "${HOME}/src/google/gnxi"
  "${HOME}/src/google/orismologer"
)

for REPO in "${REPO_LIST[@]}"; do
  echo "updating repo: ${REPO}"
  echo "----------------------------------------------------------------------"
  cd "${REPO}" || exit
  git pull
  echo ""
done
