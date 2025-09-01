#!/usr/bin/env bash
set -euo pipefail

# This script installs the Go toolchain into a temporary directory
# It now expects BUILDPACK_DIR as its first argument.

# Get BUILDPACK_DIR from the first argument passed to this script
INSTALL_GO_BUILDPACK_DIR=$1 # <--- NEW: Capture the first argument

GO_VERSION="1.23.0" # Keep this or adjust as needed
GO_OS="linux"
GO_ARCH="amd64"

GoInstallDir=$(mktemp -d -t go_install_XXX)

echo "-----> Downloading Go $GO_VERSION for $GO_OS/$GO_ARCH to $GoInstallDir"
GO_TARBALL="go${GO_VERSION}.${GO_OS}-${GO_ARCH}.tar.gz"
GO_URL="https://dl.google.com/go/${GO_TARBALL}"

curl -fL "$GO_URL" -o "$GoInstallDir/$GO_TARBALL"
if [ $? -ne 0 ]; then
  echo "       ERROR: Failed to download Go from $GO_URL. Curl exited with status $?."
  echo "       Check network connectivity from Cloud Foundry cell to dl.google.com."
  exit 1
fi

# (Optional SHA256 checksum verification block if you added it - keep it if you did)
EXPECTED_SHA256="905a297f19ead44780548933e0ff1a1b86e8327bb459e92f9c0012569f76f5e3" # SHA256 for go1.21.12.linux-amd64.tar.gz
DOWNLOADED_SHA256=$(sha256sum "$GoInstallDir/$GO_TARBALL" | awk '{print $1}')

if [ "$EXPECTED_SHA256" != "$DOWNLOADED_SHA256" ]; then
  echo "       ERROR: Downloaded Go tarball checksum mismatch!"
  echo "       Expected: $EXPECTED_SHA256"
  echo "       Got:      $DOWNLOADED_SHA256"
  echo "       The downloaded file is corrupted. This usually indicates a network/proxy issue."
  exit 1
fi


tar -xzf "$GoInstallDir/$GO_TARBALL" -C "$GoInstallDir"
if [ $? -ne 0 ]; then
  echo "       ERROR: Failed to extract Go tarball from '$GoInstallDir/$GO_TARBALL'. Tar exited with status $?."
  echo "       The file is corrupted despite matching checksum (very rare) or tar command itself has issues."
  exit 1
fi

# Set environment variables
export GOROOT="$GoInstallDir/go"
export GOPATH="$INSTALL_GO_BUILDPACK_DIR" # <--- CHANGED: Use the argument
export PATH="$GOROOT/bin:$PATH"

echo "       Go $GO_VERSION installed and configured."
rm "$GoInstallDir/$GO_TARBALL"