
# delete if any existing
rm "$HOME/newrelic-dotnet-extension.zip"

# 1. Navigate to the root of your compiled New Relic buildpack Go project
# This is where your 'bin' folder (with detect, supply, finalize) and your Gopkg.toml/Gopkg.lock are.
cd "$GOPATH/src/newrelic-dotnetcore-extension"

# 2. Create a temporary directory for packaging
mkdir -p /tmp/newrelic-dotnet-buildpack-package
BUILD_DIR="/tmp/newrelic-dotnet-buildpack-package"

# 3. Copy the compiled binaries (detect, supply, finalize)
cp -r bin "$BUILD_DIR/"

# 4. Copy the buildpack's own manifest.yml (THE ONE YOU SHARED!)
# Assuming this manifest.yml is in the current directory (your Go project root)
cp manifest.yml "$BUILD_DIR/"

# 5. Copy newrelic.config
# This file is critical for the agent. It should be in the Go project root.
# If it's not in the current directory, you need to find its location and copy it from there.
# Example if it's in the same directory:
cp newrelic.config "$BUILD_DIR/"

# 6. Copy other essential files listed in include_files:
#    - README.md
#    - VERSION
# If these files exist in your current directory, copy them:
cp README.md "$BUILD_DIR/"
cp VERSION "$BUILD_DIR/"

# 7. (Optional but important - if they exist) Handle compile and release binaries
# If the original New Relic buildpack repository has very simple shell scripts
# for 'compile' and 'release' (even if they just do nothing and exit 0),
# you might need to find them and copy them into your $BUILD_DIR/bin/.
# For now, let's proceed without them, but be aware this might be a future issue.

# 8. Zip the contents
cd "$BUILD_DIR"
zip -r "$HOME/newrelic-dotnet-extension.zip" ./*

# 9. Clean up temporary directory
rm -rf "$BUILD_DIR"
