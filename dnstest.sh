#!/usr/bin/env bash


command -v bc > /dev/null || { echo "error: bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "error: dig was not found. Please install dnsutils."; exit 1; }


NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERSV4=$(cat "$(dirname "$0")/providers-v4.txt")
PROVIDERSV6=$(cat "$(dirname "$0")/providers-v6.txt")

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
DOMAINS2TEST=$(cat "$(dirname "$0")/domainslist.txt")
# Most visted sites in the world as of may 2025 according to Similarweb and Semrush

totaldomains=0
header=""
separator=""

# Resize terminal if smaller than 19 rows or 113 columns
rows=$(tput lines)
cols=$(tput cols)
if [ "$rows" -lt 19 ] || [ "$cols" -lt 113 ]; then
    printf '\e[8;19;113t'
fi

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

results=""

csv_file="dns_results.csv"
# Write CSV header
{
    printf "DNS Resolver"
    for ((i=1; i<=totaldomains; i++)); do
        printf ",test%d" "$i"
    done
    printf ",Average\n"
} > "$csv_file"

for p in $NAMESERVERS $providerstotest; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0
    row=$(printf "%-21s" "$pname")
    csv_row="$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
            ttime=1000
        elif [ "x$ttime" = "x0" ]; then
            ttime=1
        fi

        row="$row$(printf "%-8s" "$ttime ms")"
        csv_row="$csv_row,$ttime"
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

    row="$row  ${color}$(printf "%-8s" "$avg")${NC}"
    csv_row="$csv_row,$avg"
    results="$results\n$avg_int|$row"
    echo "$csv_row" >> "$csv_file"
done

# Sort by average (first field), then print table rows
echo -e "$results" | sed '/^$/d' | sort -n -t'|' -k1,1 | cut -d'|' -f2-

echo "$separator"

echo "Results exported to $csv_file"

exit 0;
