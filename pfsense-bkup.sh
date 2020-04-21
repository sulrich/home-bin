#!/bin/bash

CURRENT_DATE=$(date +"%Y%m%d-%H%M%S")

REMOTE_PATH="sulrich@usi-gw.zenith.botwerks.net:/cf/conf/config.xml"
LOCAL_PATH="${HOME}/tmp/config-${CURRENT_DATE}.xml"
REPO_DIR="${HOME}/src/network-configs"
CONFIG_ARCH="${REPO_DIR}/usi-gw.zenith.botwerks.net/config-usi-gw.zenith.botwerks.net.xml"


echo "${REMOTE_PATH} ==> ${LOCAL_PATH}"
scp "${REMOTE_PATH}" "${LOCAL_PATH}"

CONFIG_DIFF=$(diff "${CONFIG_ARCH}" "${LOCAL_PATH}")

if [ -z "${CONFIG_DIFF}" ];
then
  echo "no change ... drop out gracefully"
  echo "deleting config pull file ${LOCAL_PATH}"
  rm "${LOCAL_PATH}"
else
  echo "configuration changes!"
  echo "${CONFIG_DIFF}"
  echo "moving new configuration into repo"
  mv "${LOCAL_PATH}" "${CONFIG_ARCH}"
  echo "checking confiugration into the git repo"
  cd "${REPO_DIR}"
  git add "${REPO_DIR}/usi-gw.zenith.botwerks.net/config-usi-gw.zenith.botwerks.net.xml"
  COMMIT_MSG="auto backup (${CURRENT_DATE}) into usi-gw repo"
  git commit -m "${COMMIT_MSG}"

fi

