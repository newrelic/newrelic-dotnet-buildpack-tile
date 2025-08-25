#!/usr/bin/env bash
set -euo pipefail

# Navigate to the root of the hwc-extension buildpack (where bin/, src/, manifest.yml are)
BUILD_BP_ROOT="$( dirname "${BASH_SOURCE[0]}" )/.."
cd "$BUILD_BP_ROOT"

echo "-----> Running local Go unit tests (optional but recommended)..."
# Assuming your Go project root is src/newrelic-hwc-extension
# (Adjust this path if your Go project is directly under hwc-extension, i.e., no 'src' folder)
(cd src/newrelic-hwc-extension && go test -v ./...) || echo "       (Go tests failed locally, but proceeding with packaging for remote compilation)"

echo "-----> Preparing buildpack .zip for upload (packaging Go source for remote compilation)..."

BUILD_DIR=$(mktemp -d -t buildpack-pkg-XXX)

# --- Copy all necessary files for the buildpack .zip into the temporary directory ---

# 1. Copy the 'bin/' directory with the SHELL WRAPPER SCRIPTS (detect, supply, finalize, compile, release)
cp -r bin "$BUILD_DIR/"

# 2. Copy the 'src/' directory containing ALL GO SOURCE CODE and the 'vendor/' folder
# This will copy 'src/newrelic-hwc-extension' into $BUILD_DIR/src/
cp -r src "$BUILD_DIR/" 

# 3. Copy the 'scripts/' directory (containing install_go.sh)
cp -r scripts "$BUILD_DIR/"

# 4. Copy the buildpack's own manifest.yml (from BUILD_BP_ROOT)
cp manifest.yml "$BUILD_DIR/"

# 5. Copy newrelic.config (from BUILD_BP_ROOT)
cp newrelic.config "$BUILD_DIR/"

# 6. Copy other essential root-level files (from BUILD_BP_ROOT, if they exist)
cp README.md "$BUILD_DIR/"
cp VERSION "$BUILD_DIR/"
# Add any other files like Procfile, pkg (if needed for packaging)
# Assuming Procfile and pkg are at the hwc-extension root:
cp Procfile "$BUILD_DIR/" 
cp -r pkg "$BUILD_DIR/"   

# 7. Zip the contents of the temporary directory
cd "$BUILD_DIR"
zip -r "$HOME/newrelic-hwc-extension.zip" ./*

# 8. Clean up
rm -rf "$BUILD_DIR"
echo "-----> Buildpack .zip created at $HOME/newrelic-hwc-extension.zip"