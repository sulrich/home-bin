#!/usr/bin/env bash
#
# paste-lol.sh - post content to paste.lol pastebin
#
# usage: paste-lol.sh [file] [title]
#   - if no file is provided, reads from clipboard
#   - title defaults to filename or timestamp if from clipboard

set -euo pipefail

# configuration
ADDRESS="sulrich"
CREDENTIALS_FILE="$HOME/.credentials/omg-lol-api.txt"

# get api key from credentials file
get_api_key() {
    if [[ ! -f "$CREDENTIALS_FILE" ]]; then
        echo "error: credentials file not found: $CREDENTIALS_FILE" >&2
        exit 1
    fi
    
    cat "$CREDENTIALS_FILE"
}

# get clipboard content
get_clipboard() {
    if command -v pbpaste &> /dev/null; then
        pbpaste
    elif command -v xclip &> /dev/null; then
        xclip -selection clipboard -o
    elif command -v xsel &> /dev/null; then
        xsel --clipboard --output
    else
        echo "error: no clipboard utility found (pbpaste, xclip, or xsel)" >&2
        exit 1
    fi
}

# main
main() {
    local content
    local title
    local api_key
    
    # get api key
    api_key=$(get_api_key)
    
    # determine content source and title
    if [[ $# -eq 0 ]]; then
        # read from clipboard
        content=$(get_clipboard)
        # use timestamp as title with clipboard prefix
        title="clipboard - $(date +"%Y%m%d-%H%M%S")"
    else
        # read from file
        if [[ ! -f "$1" ]]; then
            echo "error: file not found: $1" >&2
            exit 1
        fi
        content=$(cat "$1")
        # use filename without path as default title
        title=$(basename "$1")
    fi
    
    # override title if provided
    if [[ $# -ge 2 ]]; then
        title="$2"
    fi
    
    # post to paste.lol
    response=$(curl -s -X POST \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        "https://api.omg.lol/address/$ADDRESS/pastebin/" \
        -d "$(jq -n --arg title "$title" --arg content "$content" '{title: $title, content: $content}')")
    
    # check response
    if echo "$response" | jq -e '.request.success' > /dev/null 2>&1; then
        paste_url="https://${ADDRESS}.paste.lol/${title}"
        echo "paste created: $paste_url"
    else
        echo "error creating paste:" >&2
        echo "$response" | jq '.' >&2
        exit 1
    fi
}

main "$@"
