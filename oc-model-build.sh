#!/bin/bash

# this will generate a list of OC model paths based on the list of models that
# i keep track of in the dotfiles directory.  it does a little bit of cleanup
# and sorts the outputs. the contents of the PATH_FILE are persistently
# available in my personal environment as $OC_PATH_DUMP and exported in my
# zshenv accordingly.

# path to the openconfig model repo
OC_REPO_DIR="${HOME}/src/openconfig/public/release/models"
# collection of IETF YANG models
IETF_YANG_DRAFT="${HOME}/src/yang/standard/ietf/DRAFT"
IETF_YANG_RFC="${HOME}/src/yang/standard/ietf/RFC"
# IANA standard YANG models
IANA="${HOME}/src/yang/standard/iana"
# openconfig base directory - where i stick all oc cruft
OC_BASE="${HOME}/src/openconfig"
# pyang AST csv export destination
PATH_CSV="${HOME}/.home/openconfig/oc-path-list.csv"
PATH_FILE="${HOME}/.home/openconfig/oc-path-list.txt"
# YANG_PLUGINS directory
YANG_PLUGINS="${HOME}/src/openconfig/oc-pyang/openconfig_pyang/plugins"

source "${HOME}/.home/openconfig/model-build-list.txt"

pyang-path () {
	pyang --plugindir "${YANG_PLUGINS}" --strip -f paths $*
}

## gen-csvlist: generate the scrubbed list of OC paths
gen-csvlist() {
  # scratch file prior to frobbing into the PATH_CSV
  local TMPFILE="/tmp/oc-model-dump-pre.txt"

  cd "${OC_REPO_DIR}" || exit

  for MODEL in "${MODEL_LIST[@]}"; do 
    echo "updating model: ${MODEL}"
    pyang-path "${MODEL}" >> "${TMPFILE}"
  done

  echo -n "deleting old path file ..."
  rm "${PATH_CSV}"
  echo "done"

  echo -n "generating path file..."
  sed 's/\[..\]//' < "${TMPFILE}" \
    | sed 's/[[:space:]]//g' | sort | uniq >> "${PATH_CSV}"

    # remove spaces
    sed '/^[[:space:]]*$/d' < "${PATH_CSV}" > "${TMPFILE}"
    # append the stub fields into 
    sed 's/$/,std-path,,/' < "${TMPFILE}" > "${PATH_CSV}"
    # generate header line
    echo "path,support_status,augment,notes" > "${TMPFILE}"
    cat "${PATH_CSV}" >> "${TMPFILE}"
    mv "${TMPFILE}" "${PATH_CSV}"
    echo "done"
}

## gen-pathlist: generate the scrubbed list of OC paths
gen-pathlist() {
  gnmic generate path --file "${OC_REPO_DIR}" \
    --dir "${IETF_YANG_DRAFT}"                \
    --dir "${IETF_YANG_RFC}"                  \
    --dir "${IANA}"                           \
    --dir "${OC_REPO_DIR}"                    \
    --types > "${PATH_FILE}"
}

## gen-pathlist-stdout: generate the scrubbed list of OC paths
gen-pathlist-stdout() {
  gnmic generate path --file "${OC_REPO_DIR}" \
    --dir "${IETF_YANG_DRAFT}"                \
    --dir "${IETF_YANG_RFC}"                  \
    --dir "${IANA}"                           \
    --dir "${OC_REPO_DIR}"                    \
    --types 
}

## gen-pathlist-anetrelease: (release-dir) generate release specific YANG dump
gen-pathlist-anetrelease() {
  gnmic generate path --file                        \
     "$1/release/openconfig/models"                 \
      --dir "${1}/openconfig/public/release/models" \
    --dir "${1}/experimental/eos/models"            \
    --dir "${IETF_YANG_DRAFT}"                      \
    --dir "${IETF_YANG_RFC}"                        \
    --dir "${IANA}"                                 \
    --dir "${OC_REPO_DIR}"                          \
    --dir "${OC_BASE}/hercules/yang"                \
    --types
}


help() {
  local SCRIPT=$(basename "${0}")
  cat <<EOF

usage: 
  ${SCRIPT} command [args]

available commands:
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
