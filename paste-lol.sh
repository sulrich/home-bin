#!/usr/bin/env bash
#
# paste-lol.sh - post content to paste.lol pastebin
#
# usage: 
#   paste-lol.sh              - post clipboard content
#   paste-lol.sh <file>       - post file content
#   paste-lol.sh <file> <title> - post file with custom title
#   paste-lol.sh -l|--list    - list all pastes
#   paste-lol.sh -h|--help    - show this help message

set -euo pipefail

# configuration
ADDRESS="sulrich"
CREDENTIALS_FILE="$HOME/.credentials/omg-lol-api.txt"

# show usage information
usage() {
    cat << EOF
usage: paste-lol.sh [options] [file] [title]

post content to paste.lol pastebin

options:
    -h, --help      show this help message
    -l, --list      list all pastes

arguments:
    file            file to post (if omitted, reads from clipboard)
    title           custom title for paste (defaults to filename or timestamp)

examples:
    paste-lol.sh                    # post clipboard with timestamp
    paste-lol.sh script.sh          # post file with filename as title
    paste-lol.sh script.sh backup   # post file with custom title
    paste-lol.sh -l                 # list all pastes

credentials:
    api key should be stored in: $CREDENTIALS_FILE
EOF
}

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

# list all pastes
list_pastes() {
    local api_key
    api_key=$(get_api_key)
    
    response=$(curl -s -X GET \
        -H "Authorization: Bearer $api_key" \
        "https://api.omg.lol/address/$ADDRESS/pastebin")
    
    if ! echo "$response" | jq -e '.request.success' > /dev/null 2>&1; then
        echo "error retrieving pastes:" >&2
        echo "$response" | jq '.' >&2
        exit 1
    fi
    
    # display pastes in a formatted table
    echo "$response" | jq -r '
        .response.pastebin[] | 
        [.title, .modified_on, ("https://'"$ADDRESS"'.paste.lol/" + .title)] | 
        @tsv' | while IFS=$'\t' read -r title timestamp url; do
        # convert unix timestamp to readable date
        date_str=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null)
        printf "%-40s %s  %s\n" "$title" "$date_str" "$url"
    done
}

# main
main() {
    # check for help command
    if [[ $# -ge 1 ]] && [[ "$1" == "-h" || "$1" == "--help" ]]; then
        usage
        exit 0
    fi
    
    # check for list command
    if [[ $# -ge 1 ]] && [[ "$1" == "-l" || "$1" == "--list" ]]; then
        list_pastes
        exit 0
    fi
    
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
