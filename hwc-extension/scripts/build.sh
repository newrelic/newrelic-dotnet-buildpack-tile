#!/usr/bin/env bash
set -exuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

# GOOS=linux go build -ldflags="-s -w" -o bin/supply newrelic_hwc_extension/supply/cli
# GOOS=linux go build -ldflags="-s -w" -o bin/finalize newrelic_hwc_extension/finalize/cli
GOOS=windows go build -ldflags="-s -w" -o bin/supply.exe newrelic_hwc_extension/supply/cli
GOOS=windows go build -ldflags="-s -w" -o bin/finalize.exe newrelic_hwc_extension/finalize/cli
