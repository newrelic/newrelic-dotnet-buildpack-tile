export GOOS=linux
export GOARCH=amd64

# Create the bin directory for outputs (if it doesn't exist already in this root)
mkdir -p bin

# Build 'supply'
go build -ldflags="-s -w" -o bin/supply ./supply/cli

# Build 'finalize'
go build -ldflags="-s -w" -o bin/finalize ./finalize/cli
