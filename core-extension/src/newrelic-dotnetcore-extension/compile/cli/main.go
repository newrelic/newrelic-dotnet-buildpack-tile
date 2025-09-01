package main

import (
	"fmt"
	"os"
)

func main() {
	// Standard buildpack arguments
	// BUILD_DIR := os.Args[1]
	// CACHE_DIR := os.Args[2]
	// DEPS_DIR := os.Args[3]
	// DEPS_IDX := os.Args[4]

	fmt.Println("-----> New Relic Dotnet Extension Buildpack: Running compile phase (Go binary)")
	fmt.Println("       (This phase is mostly a pass-through for extension buildpacks; primary work is in supply/finalize)")

	os.Exit(0) // Indicate success
}

// This is a simple compile script for the New Relic Dotnet Extension Buildpack.
