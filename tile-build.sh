#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# --- Configuration ---
VERSION="1.2.8"
TILE_NAME="new-relic-dotnet-buildpack"

# Define the final buildpack filenames as specified in tile.yml
HWC_BP_FILE="newrelic-hwc-extension_buildpack-windows-v${VERSION}.zip"
HWC_CACHED_BP_FILE="newrelic-hwc-extension_buildpack-cached-windows-v${VERSION}.zip"
CORE_BP_FILE="newrelic-dotnetcore-extension_buildpack-cflinuxfs4-v${VERSION}.zip"
CORE_CACHED_BP_FILE="newrelic-dotnetcore-extension_buildpack-cached-cflinuxfs4-v${VERSION}.zip"

# Define the expected output names from the individual build scripts
HWC_SCRIPT_OUTPUT_NAME="newrelic-hwc-extension.zip"
CORE_SCRIPT_OUTPUT_NAME="newrelic-dotnetcore-extension.zip"

# --- Build Process ---

# 1. Clean up old artifacts
echo "--- Cleaning up old artifacts ---"
rm -f ./*.pivotal
rm -f ./*.zip
rm -f ./hwc-extension/*.zip
rm -f ./core-extension/*.zip
echo "Cleanup complete."
echo

# 2. Build the HWC (Windows) Extension by calling its own build script
echo "--- Building HWC (Windows) Extension Buildpack ---"
(
  cd hwc-extension
  ./scripts/build.sh
)
mv "${HWC_SCRIPT_OUTPUT_NAME}" "${HWC_BP_FILE}"
mv "${HWC_BP_FILE}" hwc-extension/
echo "Created and renamed hwc-extension/${HWC_BP_FILE}"
cp "hwc-extension/${HWC_BP_FILE}" "hwc-extension/${HWC_CACHED_BP_FILE}"
echo "Created hwc-extension/${HWC_CACHED_BP_FILE}"
echo

# 3. Build the Dotnet Core (Linux) Extension by calling its own build script
echo "--- Building Dotnet Core (Linux) Extension Buildpack ---"
(
  cd core-extension
  ./scripts/build.sh
)
mv "${CORE_SCRIPT_OUTPUT_NAME}" "${CORE_BP_FILE}"
mv "${CORE_BP_FILE}" core-extension/
echo "Created and renamed core-extension/${CORE_BP_FILE}"
cp "core-extension/${CORE_BP_FILE}" "core-extension/${CORE_CACHED_BP_FILE}"
echo "Created core-extension/${CORE_CACHED_BP_FILE}"
echo

# 4. Assemble the final .pivotal tile using the tile CLI
echo "--- Assembling the .pivotal tile using the 'tile' CLI ---"
# The 'tile build' command reads tile.yml, finds the packages at the specified paths,
# and creates a correctly structured .pivotal file.
# NOTE: This requires the 'tile' CLI to be installed.
tilev1 build

echo
echo "✅ Successfully created tile: ${TILE_NAME}-${VERSION}.pivotal"
