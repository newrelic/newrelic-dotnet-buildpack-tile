#!/usr/bin/env bash
set -euo pipefail

# Navigate to the root of the core-extension (where bin/, src/, manifest.yml are)
cd "$( dirname "${BASH_SOURCE[0]}" )/.."

echo "-----> Running local Go unit tests (optional but recommended)..."
# Assuming your Go project root is src/newrelic-dotnetcore-extension
# Ensure you are in the correct directory to run tests.
# For example, if your actual Go project root is 'src/newrelic-dotnetcore-extension':
(cd src/newrelic-dotnetcore-extension && go test -v ./...)

echo "-----> Preparing buildpack .zip for upload (packaging Go source for remote compilation)..."

BUILD_DIR=$(mktemp -d -t buildpack-pkg-XXX)

# --- Copy all necessary files for the buildpack .zip into the temporary directory ---

# 1. Copy the 'bin/' directory with the SHELL WRAPPER SCRIPTS (detect, supply, finalize, compile, release)
cp -r bin "$BUILD_DIR/"

# 2. Copy the 'src/' directory containing ALL GO SOURCE CODE and the 'vendor/' folder
cp -r src "$BUILD_DIR/" 
# Note: The 'src' folder here would contain 'newrelic-dotnetcore-extension' as a subfolder,
# and that subfolder contains 'detect', 'compile', 'supply', 'finalize', 'release' Go source,
# and the 'vendor' folder.
# The 'src' in the local buildpack's root is not the Go project's src, it's just the folder that will be unpacked.

# 3. Copy the 'scripts/' directory (containing install_go.sh)
cp -r scripts "$BUILD_DIR/"

# 4. Copy the buildpack's own manifest.yml (which should be in the current directory, `core-extension`)
cp manifest.yml "$BUILD_DIR/"

# 5. Copy newrelic.config (which should be in the current directory, `core-extension`)
cp newrelic.config "$BUILD_DIR/"

# 6. Copy other essential root-level files (from buildpack's manifest.yml include_files)
cp README.md "$BUILD_DIR/"
cp VERSION "$BUILD_DIR/"

# 7. Zip the contents of the temporary directory
cd "$BUILD_DIR"
zip -r "$HOME/newrelic-dotnet-extension.zip" ./*

# 8. Clean up
rm -rf "$BUILD_DIR"
echo "-----> Buildpack .zip created at $HOME/newrelic-dotnet-extension.zip"