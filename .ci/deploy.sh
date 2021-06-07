#!/bin/bash

set -e

proto_groups=(all les snap)

for network in "$@"; do

    echo "Deploy: $network"

    for proto in "${proto_groups[@]}"; do
        echo -n "Deploy: ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"

        # Ensure that we actually have a nodeset to deploy to DNS.
        [[ ! -d ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN} ]] || [[ ! -f ${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}/nodes.json ]] && { echo " | DNE, skipping"; continue; }

        echo
        # all.classic.blockd.info
        # les.classic.blockd.info
        # snap.classic.blockd.info <-- does this get used in geth, and where?
        devp2p dns to-cloudflare --zoneid "$ETH_DNS_CLOUDFLARE_ZONEID" "${proto}.${network}.${ETH_DNS_DISCV4_PARENT_DOMAIN}"
    done
done
