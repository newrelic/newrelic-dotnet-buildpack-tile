#!/usr/bin/env bash
set -exuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

# GOOS=linux go build -ldflags="-s -w" -o bin/supply newrelic-hwc-extension/supply/cli
# GOOS=linux go build -ldflags="-s -w" -o bin/finalize newrelic-hwc-extension/finalize/cli
GOOS=windows go build -ldflags="-s -w" -o bin/supply.exe newrelic-hwc-extension/supply/cli
GOOS=windows go build -ldflags="-s -w" -o bin/finalize.exe newrelic-hwc-extension/finalize/cli

