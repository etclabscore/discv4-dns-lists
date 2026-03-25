#!/bin/bash
set -e

# This script runs from the etccore working directory during CI.
# It reads the template from gh-pages, injects node data, and pushes
# the generated index.html back to gh-pages.

DOMAIN="blockd.info"
NETWORKS="classic mordor"
PROTOCOLS="all les snap"
COMMIT_SHA="${GITHUB_SHA:0:7}"

# Get template from gh-pages
TEMPLATE=$(git show origin/gh-pages:template.html)

# Generate HTML with embedded data
PAGE_HTML=$(python3 -c "
import json, os

domain = '${DOMAIN}'
networks = '${NETWORKS}'.split()
protocols = '${PROTOCOLS}'.split()

node_data = {}
for network in networks:
    for proto in protocols:
        path = f'{proto}.{network}.{domain}/nodes.json'
        if os.path.isfile(path):
            with open(path) as f:
                node_data[f'{proto}.{network}'] = json.load(f)

urls = {'generated': '${COMMIT_SHA}'}
blockd_path = f'all.classic.{domain}/enrtree-info.json'
if os.path.isfile(blockd_path):
    with open(blockd_path) as f:
        urls['blockd'] = json.load(f)['url']
    urls['etcdisco'] = urls['blockd'].replace('blockd.info', 'etcdisco.net')

etcdisco_path = 'all.classic.etcdisco.net/enrtree-info.json'
if os.path.isfile(etcdisco_path):
    with open(etcdisco_path) as f:
        urls['etcdisco'] = json.load(f)['url']

import sys
template = sys.stdin.read()
template = template.replace('/*__NODE_DATA__*/ {}', json.dumps(node_data, separators=(',', ':')))
template = template.replace('/*__DISCOVERY_URLS__*/ {}', json.dumps(urls, separators=(',', ':')))
print(template)
" <<< "$TEMPLATE")

# Clone gh-pages, update index.html, push
TMPDIR=$(mktemp -d)
git clone --branch gh-pages --single-branch --depth 1 \
  "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$TMPDIR"
echo "$PAGE_HTML" > "$TMPDIR/index.html"
cd "$TMPDIR"
git add index.html
git -c user.name='github-actions[bot]' -c user.email='github-actions[bot]@users.noreply.github.com' \
  commit -m "Update node explorer from ${COMMIT_SHA}" || echo "No changes to deploy"
git push
rm -rf "$TMPDIR"
echo "GitHub Pages deployed"
