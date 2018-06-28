# New Relic .NET Buildpack For PCF
This documents contains instructions on how to use New Relic Dotnet Buildpack Tile to bind New Relic agents to a Dotnet Core or Dotnet Framework application in [Pivotal Cloud Foundry][a] (PCF) environment.

There are 3 buildpacks in this tile.

* New Relic HWC Buildpack for Dotnet Framework Applications
* New Relic HWC Buildpack Cached for Dotnet Framework Applications
* New Relic Dotnet Core Extension Buildpack for Dotnet Core Applications

The 2 HWC buildpacks are similar, except the cached version is built with dependencies embedded in it for **Disconnected** environments. 

The 3rd buildpack is and extension buildpack for Dotnet Core applications, and works in conjunction with Cloud Foundry's standard Dotnet Core buildpack.

## How to Install the Buildpack
Download the latest version of the tile (currently **"newrelic-dotnet-buildpack-tile-0.2.14.pivotal"**) from this github repo under [releases][b], upload to the OpsMgr, and install it. Then **Apply changes**.

If you do not wish to install all 3 buildpacks by installing the tile, unzip the downloaded **.pivotal** file, and install only the buildpack(s) that you need using CF command **"cf create-buildpack ..."**.



[a]: https://pivotal.io/platform
[b]: https://github.com/newrelic/newrelic-dotnet-buildpack-tile/releases
