#!/usr/bin/env bash
set -euo pipefail

# This script installs the Go toolchain into a temporary directory
# It expects BUILDPACK_UNPACKED_ROOT as its first argument.

INSTALL_GO_BUILDPACK_DIR=$1 # Capture the first argument (BUILDPACK_UNPACKED_ROOT)

GO_VERSION="1.23.0" # <--- TARGETING GO 1.23.0
GO_OS="windows"     # <--- TARGETING WINDOWS BINARIES
GO_ARCH="amd64"

GoInstallDir=$(mktemp -d -t go_install_XXX)

echo "-----> Downloading Go $GO_VERSION for $GO_OS/$GO_ARCH to $GoInstallDir"
# For Windows, Go provides a .zip file, not a .tar.gz!
GO_ZIPBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.zip" # <--- .zip extension
GO_URL="https://dl.google.com/go/${GO_ZIPBALL}"

curl -fL "$GO_URL" -o "$GoInstallDir/$GO_ZIPBALL"
if [ $? -ne 0 ]; then
  echo "       ERROR: Failed to download Go from $GO_URL. Curl exited with status $?."
  echo "       Check network connectivity from Cloud Foundry cell to dl.google.com."
  exit 1
fi

# SHA256 checksum for go1.23.0.windows-amd64.zip (VERIFY THIS FROM GO'S OFFICIAL DOWNLOADS PAGE!)
# Go to https://go.dev/dl/ and find the SHA256 for go1.23.0.windows-amd64.zip
EXPECTED_SHA256="d4be481ef73079ee0ad46081d278923aa3fd78db1b3cf147172592f73e14c1ac" # <--- PLACE CORRECT SHA256 HERE
DOWNLOADED_SHA256=$(sha256sum "$GoInstallDir/$GO_ZIPBALL" | awk '{print $1}')
# Note: sha256sum might not be available by default on some minimal Linux environments.
# If you get 'sha256sum: command not found', you might need to use 'shasum -a 256' or remove this check for now.

if [ "$EXPECTED_SHA256" != "$DOWNLOADED_SHA256" ]; then
  echo "       ERROR: Downloaded Go zipball checksum mismatch!"
  echo "       Expected: $EXPECTED_SHA256"
  echo "       Got:      $DOWNLOADED_SHA256"
  echo "       The downloaded file is corrupted. This usually indicates a network/proxy issue."
  exit 1
fi

# Extract Go .zip file (using 'unzip' instead of 'tar')
unzip -q "$GoInstallDir/$GO_ZIPBALL" -d "$GoInstallDir" # <--- Use unzip
if [ $? -ne 0 ]; then
  echo "       ERROR: Failed to extract Go zipball from '$GoInstallDir/$GO_ZIPBALL'. Unzip exited with status $?."
  echo "       The file is corrupted despite matching checksum (very rare) or unzip command itself has issues."
  exit 1
fi

export GOROOT="$GoInstallDir/go"
export GOPATH="$INSTALL_GO_BUILDPACK_DIR"
export PATH="$GOROOT/bin:$PATH"

echo "       Go $GO_VERSION installed and configured."
rm "$GoInstallDir/$GO_ZIPBALL"