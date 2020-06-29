#!/bin/sh
# get google DNS locations 
# https://developers.google.com/speed/public-dns/faq#locations

IFS="\"$IFS"
LOCATIONS=locations.publicdns.goog.
RESOLVER=publicdns.goog.
for PROTO in tls tcp edns notcp; do
  for DIG in kdig dig; do
    $DIG "+$PROTO" +short . -t SOA @$RESOLVER 2>&- && break
  done
  $DIG "+$PROTO" +noall "$LOCATIONS" -t TXT "@$RESOLVER" 2>&- && break
done
for LOC in $($DIG "+$PROTO" +short "$LOCATIONS" -t TXT "@$RESOLVER")
do
  case $LOC in
    '') : ;;
    *.*|*:*) printf '%s ' "$LOC" ;;
    *) printf '%s\n' "$LOC" ;;
  esac
done
