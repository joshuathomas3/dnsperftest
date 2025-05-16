#!/usr/bin/env bash


command -v bc > /dev/null || { echo "error: bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "error: dig was not found. Please install dnsutils."; exit 1; }


NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERSV4="
1.1.1.1#cloudflare 
8.8.8.8#google 
9.9.9.9#quad9 
94.140.14.14#adguard
208.67.222.222#opendns
185.228.168.9#cleanbrowsing
76.76.2.0#controld
"

PROVIDERSV6="
2606:4700:4700::1111#cloudflare-v6
2001:4860:4860::8888#google-v6
2620:fe::fe#quad-9
2a00:5a60::ad1:0ff#adguard-v6
2620:0:ccc::2#opendns-v6
2a0d:2a00:1::2#cleanbrowsing-v6
2606:1a40::#controld-v6
"

# Testing for IPv6
$dig +short +tries=1 +time=2 +stats @2607:f8b0:4003:c00::6a www.google.com |grep 216.239.38.120 >/dev/null 2>&1
if [ $? = 0 ]; then
    hasipv6="true"
fi

providerstotest=$PROVIDERSV4

if [ "x$1" = "xipv6" ]; then
    if [ "x$hasipv6" = "x" ]; then
        echo "error: IPv6 support not found. Unable to do the ipv6 test."; exit 1;
    fi
    providerstotest=$PROVIDERSV6

elif [ "x$1" = "xipv4" ]; then
    providerstotest=$PROVIDERSV4

elif [ "x$1" = "xall" ]; then
    if [ "x$hasipv6" = "x" ]; then
        providerstotest=$PROVIDERSV4
    else
        providerstotest="$PROVIDERSV4 $PROVIDERSV6"
    fi
else
    providerstotest=$PROVIDERSV4
fi

    

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="www.google.com www.youtube.com www.facebook.com www.instagram.com chatgpt.com x.com www.whatsapp.com wikipedia.org reddit.com yahoo.co.jp"
# Most visted sites in the world as of may 2025 according to Similarweb and Semrush

totaldomains=0
header=""
separator=""

# Add table header for DNS resolver
header=$(printf "%-21s" "DNS Resolver")
separator=$(printf "%-21s" "" | tr ' ' '-')
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
    header="$header$(printf "%-8s" "test$totaldomains")"
    separator="$separator$(printf "%-8s" "" | tr ' ' '-')"
done
header="$header$(printf "%-8s" "Average")"
separator="$separator$(printf "%-8s" "" | tr ' ' '-')"

echo "$header"
echo "$separator"

# ANSI color codes
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

for p in $NAMESERVERS $providerstotest; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0

    printf "%-21s" "$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
            #let's have time out be 1s = 1000ms
            ttime=1000
        elif [ "x$ttime" = "x0" ]; then
            ttime=1
        fi

        printf "%-8s" "$ttime ms"
        ftime=$((ftime + ttime))
    done
    avg=`bc -l <<< "scale=2; $ftime/$totaldomains"`
    avg_int=${avg%.*}

    # Colorize average
    if (( avg_int < 20 )); then
        color=$GREEN
    elif (( avg_int < 150 )); then
        color=$YELLOW
    else
        color=$RED
    fi

    printf "  ${color}%-8s${NC}\n" "$avg"
done

echo "$separator"


exit 0;
