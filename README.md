# New Relic .NET Buildpack For PCF
This documents contains instructions on how to use New Relic Dotnet Buildpack Tile to bind New Relic agents to a Dotnet Core or Dotnet Framework application in [Pivotal Cloud Foundry][a] (PCF) environment.

There are 3 buildpacks in this tile.

* New Relic HWC Buildpack for Dotnet Framework Applications
* New Relic HWC Buildpack Cached for Dotnet Framework Applications
* New Relic Dotnet Core Extension Buildpack for Dotnet Core Applications

The 2 HWC buildpacks are similar, except the cached version is built with dependencies embedded in it for **Disconnected** environments. 

The 3rd buildpack is and extension buildpack for Dotnet Core applications, and works in conjunction with Cloud Foundry's standard Dotnet Core buildpack.

## How to Install the Buildpack
Download the latest version of the tile (currently v0.2.12) from this github repo under releases, upload to the OpsMgr, and install it. Then **Apply changes**.




[a]: https://pivotal.io/platform
