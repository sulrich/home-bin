#!/bin/bash

# path to the openconfig model repo
OC_REPO_DIR="${HOME}/src/openconfig/public/release/models"
# export destination
PATH_FILE="${HOME}/.home/openconfig/oc-path-list.txt"
# scratch file prior to frobbing into the PATH_FILE
TMPFILE="/tmp/oc-model-dump-pre.txt"
# YANG_PLUGINS directory
YANG_PLUGINS="${HOME}/.pyang"

source "${HOME}/.home/openconfig/model-build-list.txt"

pyang-path () {
	pyang --plugindir "${YANG_PLUGINS}" --strip -f paths $*
}

cd "${OC_REPO_DIR}" || exit

for MODEL in "${MODEL_LIST[@]}"; do 
  echo "updating model: ${MODEL}"
  pyang-path "${MODEL}" >> "${TMPFILE}"
done

echo "generating path file... "
echo "path, foo" > "${PATH_FILE}"
awk '{print $2}' < "${TMPFILE}" | sort | uniq >> "${PATH_FILE}"

sed '/^[[:space:]]*$/d' < "${PATH_FILE}" > "${TMPFILE}"
mv "${TMPFILE}" "${PATH_FILE}"

