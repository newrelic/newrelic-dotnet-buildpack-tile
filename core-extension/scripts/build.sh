#!/usr/bin/env bash
set -euo pipefail

# Navigate to the root of the core-extension (where bin/, src/, manifest.yml are)
BUILD_BP_ROOT="$( dirname "${BASH_SOURCE[0]}" )/.."
cd "$BUILD_BP_ROOT"

# --- FIX: Define absolute path for the output zip file ---
# The project root is one level up from our current directory.
PROJECT_ROOT="$(pwd)/.."
OUTPUT_ZIP_NAME="newrelic-dotnetcore-extension.zip"
OUTPUT_ZIP_PATH="${PROJECT_ROOT}/${OUTPUT_ZIP_NAME}"
# --- END FIX ---

# Define the Go command to use (it's your default 'go' which is 1.19.13)
GO_COMMAND="go" 

# Define the path to the actual Go project root within this buildpack
GO_PROJECT_ROOT="src/newrelic-dotnetcore-extension"

# ... (rest of the script, before BUILD_DIR=$(mktemp -d -t buildpack-pkg-XXX) ) ...

# echo "-----> Skipping local Go compilation/tests and proceeding to packaging..."
# echo "       (This buildpack's Go components will be compiled remotely on Cloud Foundry cell)"

BUILD_DIR=$(mktemp -d -t buildpack-pkg-XXX)

# --- NEW DEBUGGING LINES FOR PACKAGING ---
echo "-----> Debugging Packaging Process:"
echo "       Current directory for packaging: $(pwd)"
echo "       Contents of 'src/' before copying:"
ls -lR src/ # Show what's in the local src/ directory
echo "       Running cp -r -v src to $BUILD_DIR/"
cp -r -v src "$BUILD_DIR/" # Added -v for verbose copy output
echo "       Contents of '$BUILD_DIR/src' after copying:"
ls -lR "$BUILD_DIR/src" # Show what actually landed in the temp build dir
echo "--- End Packaging Debugging ---"
# --- END NEW DEBUGGING LINES ---

# --- Copy all necessary files for the buildpack .zip into the temporary directory ---

# 1. Copy the 'bin/' directory with the SHELL WRAPPER SCRIPTS (detect, supply, finalize, compile, release)
cp -r bin "$BUILD_DIR/"

# 2. Copy the 'src/' directory containing ALL GO SOURCE CODE and the 'vendor/' folder
# This line is now covered by the debug block above.
# cp -r src "$BUILD_DIR/" 

# 3. Copy the 'scripts/' directory (containing install_go.sh)
cp -r scripts "$BUILD_DIR/"

# 4. Copy the buildpack's own manifest.yml (from BUILD_BP_ROOT)
cp manifest.yml "$BUILD_DIR/"

# 5. Copy newrelic.config (from BUILD_BP_ROOT)
cp newrelic.config "$BUILD_DIR/"

# 6. Copy other essential root-level files (from BUILD_BP_ROOT, if they exist)
cp README.md "$BUILD_DIR/"
cp VERSION "$BUILD_DIR/"


# 8. Zip the contents of the temporary directory
cd "$BUILD_DIR"
# --- FIX: Use the absolute path variable for the zip output ---
zip -r "${OUTPUT_ZIP_PATH}" ./*

# 9. Clean up
rm -rf "$BUILD_DIR"
# --- FIX: Use the absolute path variable in the log message ---
echo "-----> Buildpack .zip created at ${OUTPUT_ZIP_PATH}"