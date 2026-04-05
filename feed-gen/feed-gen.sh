#!/bin/bash

# the sourced file should populate the following variables.
# FEED_GEN_WWW_DIR   - web root for RSS output (rss files land in <www>/rss/)
# FEED_GEN_REPORT_DIR - where markdown reports go (e.g. obsidian vault path)
# FEED_GEN_CACHE_DIR  - where state/cache files live between runs
# FEC_API_KEY         - API key for FEC data (optional, defaults to DEMO_KEY)

source "${HOME}/.credentials/feed-gen.env"
export PATH="${HOME}/.local/bin:/opt/homebrew/bin:${PATH}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

${SCRIPT_DIR}/mn_politics_monitor.py --markdown  \
  --www-dir "${FEED_GEN_WWW_DIR}" \
  --report-dir "${FEED_GEN_REPORT_DIR}" \
  --cache-dir "${FEED_GEN_CACHE_DIR}"

${SCRIPT_DIR}/mn8_fec_monitor.py --markdown \
  --www-dir "${FEED_GEN_WWW_DIR}" \
  --report-dir "${FEED_GEN_REPORT_DIR}" \
  --cache-dir "${FEED_GEN_CACHE_DIR}"

${SCRIPT_DIR}/mn8_news_monitor.py --markdown \
  --www-dir "${FEED_GEN_WWW_DIR}" \
  --report-dir "${FEED_GEN_REPORT_DIR}" \
  --cache-dir "${FEED_GEN_CACHE_DIR}"
