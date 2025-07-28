# Set environment variables for macOS target
export GOOS=darwin
# For Intel Macs:
export GOARCH=amd64
# For Apple Silicon (M1/M2/M3) Macs:
# export GOARCH=arm64

# Create the bin directory for outputs (if it doesn't exist)
mkdir -p bin

# Build 'supply' for macOS
go build -ldflags="-s -w" -o bin/supply ./supply/cli

# Build 'finalize' for macOS
go build -ldflags="-s -s" -o bin/finalize ./finalize/cli
