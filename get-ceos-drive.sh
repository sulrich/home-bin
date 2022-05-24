#!/bin/bash
# -*- mode: sh; fill-column: 78; comment-column: 50; tab-width: 2 -*-

trap cleanup SIGINT SIGTERM ERR

# rclone remote directory - assumes rclone has been configured appropriately
# and a modern version of rclone is in use.
RCLONE_REMOTE="anet-google-b4:eos-software"
# place to stick the downloaded images
RCLONE_LOCAL="${HOME}/tmp/rclone-local"
# directory to place the exported OCI images
OCI_IMAGE_DIR="${HOME}/tmp/oci"
usage() {
    cat << EOF
usage: ${0##*/} [-h]

  see the head of this script for additional information and the relevant
  directories to create.  the rclone functions are helpers to do things
  remotely.

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
  remove-oci-images
  exit
  # script cleanup here, tmp files, etc.
}

# pullImagesRclone(date): date in YYYYMMDD format
pullImagesRclone() {
  local DROP_DIR="${RCLONE_LOCAL}/${1}-weekly/"
  mkdir -p "${DROP_DIR}"
  echo "pulling images you will be prompted for the rclone config password ..."
  rclone copyto "${RCLONE_REMOTE}/${1}-weekly/" \
    "${DROP_DIR}" --include "*cEOS-lab.tar.xz"
}

# pushImagesRclone(date): date in YYYYMMDD format
pushImagesRclone() {
  echo "pushing images you will be prompted for the rclone config password ..."
  rclone copyto "${OCI_IMAGE_DIR}/${1}-weekly/" \
    "${RCLONE_REMOTE}/${1}-weekly/" --include "*cEOS*"
}

# args:
# - image date (YYYYMMDD format)
# - docker image to import (tarball format)
dockerProcess() {
  local DROP_DIR="${RCLONE_LOCAL}/${1}-weekly/"
  local IMAGE_HASH=$(docker import "${DROP_DIR}/${2}" "ceos:${1}-${3}")
}

# EOS64-Google-B4-YYYYMMDD-cEOS-lab.tar.xz
parseArch() {
  if [[ "${1}" =~ "EOS64" ]]
  then
    echo "64b"
  else
    echo "32b"
  fi
}

# convertCeosImages(date): date in YYYYMMDD format for the drop of interest
# converts all of the files in the RCLONE_LOCAL directory
convertCeosImages() {
  local DROP_DIR="${RCLONE_LOCAL}/${1}-weekly/"
  for img in "${DROP_DIR}"/*; do
    img=$(basename $img)
    arch=$(parseArch "${img}")
    dockerProcess "${1}" "${img}" "${arch}"
  done
}

## convert-images date [rclone]: date in YYYYMMDD format
##                             : rclone (optional) do file the xfer w/rclone
## : if rclone is not specified, converted images will be placed within the
## : $OCI_IMAGE_DIR for transfer to gDrive.
convert-images() {
  if [[ "${2}" =~ "rclone" ]]
  then
    pullImagesRclone "${1}"
    convertCeosImages "${1}"
  else
    convertCeosImages "${1}"
  fi
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
