#!/bin/bash

MERGE_DIR="/mnt/snuffles/media/GCP-MediaBackup/photo-archive"
exiftool "-Directory<DateTimeOriginal" -d "${MERGE_DIR}/%Y/%m/%d" $@
