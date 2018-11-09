#!/usr/bin/env bash
set -exuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

GOOS=linux go build -ldflags="-s -w" -o bin/supply newrelic_dotnetcore_extension/supply/cli
GOOS=linux go build -ldflags="-s -w" -o bin/finalize newrelic_dotnetcore_extension/finalize/cli
