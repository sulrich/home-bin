#!/bin/zsh

SRC_DIR="/mnt/bigbird/media/Pictures/"
DEST_BUCKET="s3://sulrich-home-pics"

s3cmd sync ${SRC_DIR} ${DEST_BUCKET}
