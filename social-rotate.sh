#!/usr/bin/env bash

trap cleanup SIGINT SIGTERM ERR EXIT


usage() {
    cat << EOF
usage: ${0##*/} [-h]

    -h          display help and exit
    XXX - list of args here

EOF
}

## 1. set-external-dns: placeholder
set-external-dns() {
  echo "this is a reminder to go and point the external DNS to the gw CNAME"
  echo 
  echo "the unbound config on the local resolver will need to be updated to"
  echo "pass things through" 
}

## 2. request-cert: update the certbot request (sudo)
request-cert() {
  sudo certbot certonly -d botwerks.social \
    --webroot -w "/home/sulrich/prod/mastodon/nginx/webroot/botwerks.social"
  sudo certbot certonly -d files.botwerks.social \
    --webroot -w "/home/sulrich/prod/mastodon/nginx/webroot/files.botwerks.social"
}

## 3. restart-nginx: restart nginx to pick up the updated certs
restart-nginx() {
  docker-compose -f /home/sulrich/prod/mastodon/docker-compose.yml restart http
}


## 4. remove-ext-dns: a reminder remove external DNS pointers
remove-ext-dns() {
cat <<EOF
go and delete the existing CNAME entries that were temporarily stubbed in to
point at the external router entry. 

EOF
}

## 5. connect-tunnels: (re)establish cloudflare tunnel mapping
connect-tunnels() {
  # TODO(sulrich) - remove the DNS entries that were previously pointing at the
  # external interface.

  # route the outside world over these tunnels
  cloudflared tunnel route dns botwerks-social botwerks.social
  cloudflared tunnel route dns botwerks-social files.botwerks.social
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

    # script cleanup here, tmp files, etc.
}

if [[ $# -lt 1 ]]; then
  help
  exit
fi

# TODO(sulrich) there should probably be some sort of check here to make sure
# that we're running this script on the right host and thrown an error if we
# attempt to run this on the wrong spot.
#
case $1 in
  *)
    # shift positional arguments so that arg 2 becomes arg 1, etc.
    CMD=$1
    shift 1
    ${CMD} ${@} || help
    ;;
esac
