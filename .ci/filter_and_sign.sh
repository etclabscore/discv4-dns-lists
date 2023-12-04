#!/bin/bash

set -e

proto_groups=(all les snap)

# CloudFlare limits the number od DNS records per zone to 3500 for our account.
# For this reason we need to limit the number of nodes per network (classic|mordor) and per proto (all|les|snap).
# https://developers.cloudflare.com/dns/troubleshooting/faq/#does-cloudflare-limit-number-of-dns-records-a-domain-can-have

declare -A LIMIT_OUTPUT_SIZE_MAP

# Classic
LIMIT_OUTPUT_SIZE_MAP["classic_all"]=1400
LIMIT_OUTPUT_SIZE_MAP["classic_snap"]=1400
LIMIT_OUTPUT_SIZE_MAP["classic_les"]=50

# Mordor
LIMIT_OUTPUT_SIZE_MAP["mordor_all"]=300
LIMIT_OUTPUT_SIZE_MAP["mordor_snap"]=300
LIMIT_OUTPUT_SIZE_MAP["mordor_les"]=50

for network in "$@"; do

    echo "Filter: $network"

    mkdir -p "all.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"
    devp2p nodeset filter all.json -eth-network "$network" >"all.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json"

    # sort nodes by lastResponse and score and limit the output number
    cat "all.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json" | jq 'to_entries | sort_by(.value.lastResponse, .value.score) | reverse | .[:'${LIMIT_OUTPUT_SIZE_MAP["${network}_all"]}'] | from_entries' > "all.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.json"


    mkdir -p "les.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"
    devp2p nodeset filter all.json -les-server -eth-network "$network" >"les.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json"

    # sort nodes by lastResponse and score and limit the output number
    cat "les.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json" | jq 'to_entries | sort_by(.value.lastResponse, .value.score) | reverse | .[:'${LIMIT_OUTPUT_SIZE_MAP["${network}_les"]}'] | from_entries' > "les.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.json"

    mkdir -p "snap.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"
    devp2p nodeset filter all.json -snap -eth-network "$network" >"snap.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json"

    # sort nodes by lastResponse and score and limit the output number
    cat "snap.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.all.json" | jq 'to_entries | sort_by(.value.lastResponse, .value.score) | reverse | .[:'${LIMIT_OUTPUT_SIZE_MAP["${network}_snap"]}'] | from_entries' > "snap.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.json"

    echo "Sign: $network"

    for proto in "${proto_groups[@]}"; do
        echo -n "Sign: ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"

        # Ensure that we actually have a nodeset to sign.
        [ ! -d ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN} ] || [ ! -f ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.json ] && { echo " | DNE, skipping"; continue; }

        echo
        cat "${ETH_DNS_DISCV4_KEYPASS_PATH}" | devp2p dns sign "${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}" "${ETH_DNS_DISCV4_KEY_PATH}" && echo "OK"

        git add "${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"
    done

    ETH_DNS_DISCV4_KEY_PUBLICINFO="$(cat $ETH_DNS_DISCV4_KEYPASS_PATH | ethkey inspect $ETH_DNS_DISCV4_KEY_PATH | grep -E '(Addr|Pub)')"
    git -c user.name="meows" -c user.email='b5c6@protonmail.com' commit --author "crawler <>" -m "ci update ($network) $GITHUB_RUN_ID:$GITHUB_RUN_NUMBER
        
Crawltime: $ETH_DNS_DISCV4_CRAWLTIME

$ETH_DNS_DISCV4_KEY_PUBLICINFO"
    
done
