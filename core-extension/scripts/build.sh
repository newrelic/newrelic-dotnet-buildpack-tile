#!/usr/bin/env bash
set -exuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

GOOS=linux go build -ldflags="-s -w" -o bin/supply newrelic-dotnetcore-extension/supply/cli
GOOS=linux go build -ldflags="-s -w" -o bin/finalize newrelic-dotnetcore-extension/finalize/cli
