Filename: brats.sh
#!/usr/bin/env bash
# Test that the compiled binaries of the buildpacks are working as expected

set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc
./scripts/install_tools.sh

GINKGO_NODES=${GINKGO_NODES:-3}
GINKGO_ATTEMPTS=${GINKGO_ATTEMPTS:-1}

cd src/*/brats

echo "Run Buildpack Runtime Acceptance Tests"
ginkgo -r --flakeAttempts=$GINKGO_ATTEMPTS -nodes $GINKGO_NODES
-e 

Filename: build.sh
#!/usr/bin/env bash
set -exuo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

# GOOS=linux go build -ldflags="-s -w" -o bin/supply newrelic-hwc-extension/supply/cli
# GOOS=linux go build -ldflags="-s -w" -o bin/finalize newrelic-hwc-extension/finalize/cli
GOOS=windows go build -ldflags="-s -w" -o bin/supply.exe newrelic-hwc-extension/supply/cli
GOOS=windows go build -ldflags="-s -w" -o bin/finalize.exe newrelic-hwc-extension/finalize/cli

-e 

Filename: install_go.sh
#!/bin/bash
set -euo pipefail

GO_VERSION="1.23"
export GoInstallDir="/tmp/go$GO_VERSION"
mkdir -p $GoInstallDir

if [ ! -f $GoInstallDir/go/bin/go ]; then
GO_SHA256="244200952f414e9ae6269d32569722a7cd88435f5c52d488cd9599b8bfa1498b"
URL=https://buildpacks.cloudfoundry.org/dependencies/go/go${GO_VERSION}.linux-amd64-${GO_SHA256:0:8}.tar.gz

echo "-----> Download go ${GO_VERSION}"
curl -s -L --retry 15 --retry-delay 2 $URL -o /tmp/go.tar.gz

DOWNLOAD_SHA256=$(shasum -a256 /tmp/go.tar.gz | cut -d ' ' -f 1)
if [[ $DOWNLOAD_SHA256 != $GO_SHA256 ]]; then
echo "       **ERROR** SHA256 mismatch: got $DOWNLOAD_SHA256 expected $GO_SHA256"
exit 1
fi

tar xzf /tmp/go.tar.gz -C $GoInstallDir
rm /tmp/go.tar.gz
fi
if [ ! -f $GoInstallDir/go/bin/go ]; then
echo "       **ERROR** Could not download go"
exit 1
fi
-e 

Filename: install_tools.sh
#!/bin/bash
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc

if [ ! -f .bin/ginkgo ]; then
(cd src/*/vendor/github.com/onsi/ginkgo/ginkgo/ && go install)
fi
if [ ! -f .bin/buildpack-packager ]; then
(cd src/*/vendor/github.com/cloudfoundry/libbuildpack/packager/buildpack-packager && go install)
fi-e 

Filename: integration.sh
#!/usr/bin/env bash
# Runs the integration tests
set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc
./scripts/install_tools.sh

GINKGO_NODES=${GINKGO_NODES:-3}
GINKGO_ATTEMPTS=${GINKGO_ATTEMPTS:-2}

cd src/*/integration

echo "Run Uncached Buildpack"
ginkgo -r --flakeAttempts=$GINKGO_ATTEMPTS -nodes $GINKGO_NODES --slowSpecThreshold=60 -- --cached=false

echo "Run Cached Buildpack"
ginkgo -r --flakeAttempts=$GINKGO_ATTEMPTS -nodes $GINKGO_NODES --slowSpecThreshold=60 -- --cached
-e 


Filename: unit.sh
#!/usr/bin/env bash
# Runs the unit tests for this buildpack

set -euo pipefail

cd "$( dirname "${BASH_SOURCE[0]}" )/.."
source .envrc
./scripts/install_tools.sh

cd src/*/integration/..
ginkgo -r -skipPackage=brats,integration
-e 

