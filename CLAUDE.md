# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **VMware Tanzu (PCF) tile** that packages New Relic .NET monitoring as Cloud Foundry extension buildpacks. The tile installs up to four buildpacks into a CF environment via Ops Manager:

| Buildpack Name | Stack | Order |
|---|---|---|
| `nr_dotnetcore_extension` | cflinuxfs4 (Ubuntu Jammy) | 31 |
| `nr_dotnetcore_extension_cached` | cflinuxfs4 | 32 |
| `nr_hwc_extension` | windows | 33 |
| `nr_hwc_extension_cached` | windows | 34 |

These are **supply-phase extension buildpacks** — they must be pushed alongside the primary buildpack (dotnet-core or HWC) using CF's multi-buildpack feature. The extension injects the New Relic agent and writes a `profile.d` script to set the required `CORECLR_*` environment variables at app startup.

## Build Commands

### Build the full .pivotal tile
```bash
./tile-build.sh
```
Requires `tilev1` CLI installed. Builds both extensions, renames the ZIPs to match paths in `tile.yml`, then runs `tilev1 build`.

### Build individual extension buildpacks

**Core extension (Linux/Jammy):**
```bash
cd core-extension
source .envrc        # sets GOPATH=$PWD, GOBIN=$PWD/.bin
./scripts/install_tools.sh   # installs ginkgo and buildpack-packager from vendor
./scripts/build.sh   # produces newrelic-dotnetcore-extension.zip at repo root
```

**HWC extension (Windows):**
```bash
cd hwc-extension
source .envrc
./scripts/install_tools.sh
./scripts/build.sh   # produces newrelic-hwc-extension.zip at repo root
```

### Run tests

**Unit tests (core extension):**
```bash
cd core-extension
source .envrc
./scripts/unit.sh    # runs: ginkgo -r -skipPackage=brats,integration
```

**Run a single test package:**
```bash
cd core-extension
source .envrc
./scripts/install_tools.sh
cd src/newrelic-dotnetcore-extension
ginkgo -r supply/   # run just the supply package tests
```

**Integration tests:**
```bash
cd core-extension
./scripts/integration.sh
```

## Architecture

### Go source structure

Both extensions follow the same layout:
```
{core,hwc}-extension/
  bin/              # Shell (or .bat) wrapper scripts called by CF during staging
  src/<pkg-name>/
    supply/         # Core logic: supply.go implements Supplier.Run()
    vendor/         # All dependencies vendored (libbuildpack, ginkgo, gomega, etc.)
  scripts/          # build.sh, unit.sh, integration.sh, install_tools.sh, install_go.sh
  manifest.yml      # Buildpack manifest (lists "newrelic" dependency entry for cached builds)
  newrelic.config   # Default New Relic XML config bundled with the buildpack
  VERSION           # Semver string used by tile-build.sh
  .envrc            # Must be sourced before running any go/ginkgo commands
```

### How the supply phase works (`supply/supply.go`)

`Supplier.Run()` is the entry point. It:

1. **Detects** whether to install: checks `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_DOWNLOAD_URL`, or a `newrelic`-named service in `VCAP_SERVICES` (service broker or user-provided).
2. **Determines agent download method** (in priority order):
   - `NEW_RELIC_DOWNLOAD_URL` env var → downloads from that URL
   - Cached buildpack → copies agent tarball from `buildpackDir` (set via `manifest.yml` dependency entry)
   - `NEW_RELIC_AGENT_VERSION` env var → constructs download URL for that version
   - Default → fetches latest version from `nr-downloads-main.s3.amazonaws.com` bucket XML
3. **Extracts** the agent tarball into `$DEPS_DIR/<idx>/` (either `newrelic-netcore20-agent` for old versions or `newrelic-dotnet-agent` for v10+).
4. **Copies** `newrelic.config` with precedence: app folder > buildpack folder > agent default.
5. **Writes** `deps/<idx>/profile.d/newrelic.sh` with `CORECLR_NEWRELIC_HOME`, `CORECLR_PROFILER_PATH`, `CORECLR_ENABLE_PROFILING`, `CORECLR_PROFILER`, plus license key and app name resolved from `VCAP_APPLICATION`/`VCAP_SERVICES`.

### Tile packaging (`tile.yml`)

`tile.yml` defines the four packages with their `pre_deploy`/`deploy`/`delete` scripts. The `deploy` scripts use `cf create-buildpack` / `cf update-buildpack` with stack assignment. The `pre_deploy` script in the first package cleans up any stack-less (`NF == 5` in `cf buildpacks` output) legacy buildpacks left from older tile versions.

## Version Bumping

The version string appears in three places and must be kept in sync:
1. `tile-build.sh` — `VERSION="x.y.z"` variable and all hardcoded ZIP filenames
2. `tile.yml` — `version:` field and all hardcoded ZIP paths in `packages[*].path` and `deploy` scripts
3. `core-extension/VERSION` and `hwc-extension/VERSION` files

## Key Environment Variables (app staging)

| Variable | Effect |
|---|---|
| `NEW_RELIC_LICENSE_KEY` | Triggers agent installation; sets license key |
| `NEW_RELIC_DOWNLOAD_URL` | Download agent from custom URL instead of NR CDN |
| `NEW_RELIC_DOWNLOAD_SHA256` | Expected SHA256 for `NEW_RELIC_DOWNLOAD_URL` |
| `NEW_RELIC_AGENT_VERSION` | Request a specific agent version from NR CDN |
| `NEW_RELIC_APP_NAME` | Overrides app name derived from `VCAP_APPLICATION` |
