#!/bin/bash

# the sourced file should populate the following variables.
# PR_SHEET_ID - the google sheets id to be populated
# GSHEETS_CREDS - path to the json file with the associated creds for gsheets
# REPO_DIR - path to the repo we're interested in

source "${HOME}/.credentials/pr-sheets.env"
export PATH="${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"

cd "${REPO_DIR}"

${HOME}/bin/nh-pr-fetch.py --quiet --gsheet "${PR_SHEET_ID}" \
  --credentials  "${GSHEETS_CREDS}"
