#!/usr/bin/env bash

error() {>&2 printf "ERROR:\\t%s\\n" "$2"}

run() {
# Files
# FILE_LOG='/var/cloudflare_ddns/addresses.log.csv'

# Cloudflare data
CF_API='https://api.cloudflare.com/client/v4'
CF_EMAIL="$(head -n1 ~cloudflare/credentials.txt)"
CF_KEY="$(tail -n1 ~cloudflare/credentials.txt)"
CF_DOMAIN="$(tail -n1 ~cloudflare/domain.txt)"
CF_SUBDOMAIN="$(head -n1 ~cloudflare/domain.txt)"
CF_HEADERS="-H \"Content-Type:application/json\" \
    -H \"X-Auth-Key:$CF_KEY\" \
    -H \"X-Auth-Email:$CF_EMAIL\""

# Get IP addresses
IPV4_CURRENT=$(curl -fsSL ipv4.icanhazip.com || printf '0.0.0.0') || error 'Failed to contact icanhazip over IPv4, logging address as 0.0.0.0'
IPV6_CURRENT=$(curl -fsSL ipv6.icanhazip.com || printf '::') || error 'Failed to contact icanhazip over IPv6, logging address as ::'

# no connection
if [ $IPV4_CURRENT == "0.0.0.0" ]; then
    error 'No connection to the Internet.'
	exit 101
fi

# bool
CHANGED_IPV4=false
CHANGED_IPV6=false

# cURL headers
CURL="curl -fskSL \
  -H Content-Type:application/json \
  -H X-Auth-Key:$CF_KEY \
  -H X-Auth-Email:$CF_EMAIL "

# Get cloudflare IDs
CF_ZONE_ID="$($CURL "$CF_API/zones?name=$CF_DOMAIN" | sed -e 's/[{}]/\n/g' | grep '"name":"'"$CF_DOMAIN"'"' | sed -e 's/,/\n/g' | grep '"id":"' | cut -d'"' -f4)" || error "Zone IDs not retrieved."

CF_RECORD_ID_4="$($CURL "$CF_API/zones/$CF_ZONE_ID/dns_records?type=A&name=$CF_SUBDOMAIN.$CF_DOMAIN" | sed -e 's/[{}]/\n/g' | grep '"name":"'"$CF_SUBDOMAIN"'.'"$CF_DOMAIN"'"' | sed -e 's/,/\n/g' | grep '"id":"' | cut -d'"' -f4)" || error "ID not retrieved for A record."
CF_RECORD_ID_6="$($CURL "$CF_API/zones/$CF_ZONE_ID/dns_records?type=AAAA&name=$CF_SUBDOMAIN.$CF_DOMAIN" | sed -e 's/[{}]/\n/g' | grep '"name":"'"$CF_SUBDOMAIN"'.'"$CF_DOMAIN"'"' | sed -e 's/,/\n/g' | grep '"id":"' | cut -d'"' -f4)" || error "ID not retrieved for AAAA record."

# Get IP addresses on CloudFlare
CF_RECORD_IPV4="$($CURL "$CF_API/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_4" | sed -e 's/[{}]/\n/g' | sed -e 's/,/\n/g' | grep '"content":"' | cut -d'"' -f4)" || error 'Current IP not retrieved from A record.'
CF_RECORD_IPV6="$($CURL "$CF_API/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_6" | sed -e 's/[{}]/\n/g' | sed -e 's/,/\n/g' | grep '"content":"' | cut -d'"' -f4)" || error 'Current IP not retrieved from AAAA record.'

# Write if IPv4 inconsistent
if [ "$IPV4_CURRENT" != "$CF_RECORD_IPV4" ]; then
    $CURL -X PUT "$CF_API/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_4" --data '{"type":"A","name":"'"$CF_SUBDOMAIN"'","content":"'"$IPV4_CURRENT"'","proxied":false}' 1>/dev/null || error 'Failed to rewrite A record.'
    CHANGED_IPV4=true
fi

# Write if IPv6 inconsistent
if [ "$IPV6_CURRENT" != "$CF_RECORD_IPV6" ]; then
    $CURL -X PUT "$CF_API/zones/$CF_ZONE_ID/dns_records/$CF_RECORD_ID_6" --data '{"type":"AAAA","name":"'"$CF_SUBDOMAIN"'","content":"'"$IPV6_CURRENT"'","proxied":false}' 1>/dev/null || error 'Failed to rewrite AAAA record.'
    CHANGED_IPV6=true
fi

if $CHANGED_IPV4 || $CHANGED_IPV6; then
    LOG="$(date -I'seconds')"

    if $CHANGED_IPV4; then
        LOG="$LOG changed IPv4 address to $IPV4_CURRENT,"
    fi

    if $CHANGED_IPV6; then
        LOG="$LOG changed IPv6 address to $IPV6_CURRENT."
    else
        LOG="$LOG."
    fi

    echo "$LOG"
fi
}
run
