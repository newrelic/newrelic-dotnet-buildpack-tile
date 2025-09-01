package main

import (
	"fmt"
	"os"
)

func main() {
	// Standard buildpack arguments (we don't strictly need them all for detect, but it's good practice)
	// BUILD_DIR := os.Args[1]
	// CACHE_DIR := os.Args[2]
	// DEPS_DIR := os.Args[3]
	// DEPS_IDX := os.Args[4]

	fmt.Println("-----> New Relic Dotnet Extension Buildpack: Running detect phase (Go binary)")

	// Check for NEW_RELIC_LICENSE_KEY environment variable
	licenseKey := os.Getenv("NEW_RELIC_LICENSE_KEY")
	if licenseKey == "" {
		fmt.Println("       NEW_RELIC_LICENSE_KEY environment variable not set. New Relic buildpack will NOT apply.")
		os.Exit(1) // Fail detection
	}

	// We could add more sophisticated detection logic here, e.g., checking if it's a .NET app already

	fmt.Println("       NEW_RELIC_LICENSE_KEY found. New Relic buildpack DETECTED.")
	os.Exit(0) // Pass detection
}

// This is a simple detect script for the New Relic Dotnet Extension Buildpack.
