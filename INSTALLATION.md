---
# Installing and Configuring New Relic Dotnet Extension Buildpack

---

<br/><br/>

This topic describes the installation and configuration of New Relic Dotnet Extension Buildpack(s) for Pivotal Cloud Foundry (PCF).

You can either install the buildpacks as a tile in Ops Manager, or push them individually as a separate buildpacks using CF CLI.


## <a id='install-opsmgr'></a> Install and Configure Dotnet Extension as a Tile in Ops Manager

1. Download the latest version of the tile (currently <strong>"newrelic-dotnet-buildpack-1.1.0.pivotal"</strong>) from [PivNet](https://network.pivotal.io/products/newrelic-dotnet-buildpack), or from New Relic's github repo under [releases](https://github.com/newrelic/newrelic-dotnet-buildpack-tile/releases).
1. Navigate to Ops Manager Installation Dashboard and click <strong>Import a Product</strong> to upload the product file.
1. Under the <strong>Import a Product</strong> button, click the <strong>"+"</strong> sign next to the version number of <strong>New Relic Dotnet Buildpack for PCF</strong>. This adds the tile to your staging area.
1. Click the newly added <strong>New Relic Dotnet Buildpack for PCF</strong> tile.
1. Install and configure the tile in OpsMgr. you can accept the default values and install all 4 buildpacks in your PCF foundation, or in <strong>Tile Configuration->New Relic Buildpack Selection</strong> you could select the checkbox for any of the buildpacks that you wish to install.
1. If you make any configuration changes, click the <strong>"Save"</strong> button on each tab at the bottom of the page.
1. Go to <strong>Installation UI</strong> of OpsMgr.
1. Click on the blue button on top right of the installation UI to <strong>Apply changes</strong>.

<br/>

## <a id='install-buildpack'></a> Install and Configure Dotnet Extension with CF CLI

If you do not wish to install the tile, you could alternatively unzip the downloaded <strong>.pivotal</strong> file, and install the buildpack(s) which you need using CF CLI command <strong>"cf create-buildpack ..."</strong>.

1. Unzip <strong>"newrelic-dotnet-buildpack-tile-*.pivotal"</strong> into a separate subdirectory<br/>
```
    unzip newrelic-dotnet-buildpack-tile-*.pivotal -d buildpack_tile
```

2. Change directory to buildpack_tile/releases<br/>
```
    cd buildpack_tile/releases
```

3. Create a subdirectory (i.e. tmp)<br/>
```
    mkdir tmp
```

4. Extract the <strong>.tgz</strong> file in releases folder into the <strong>tmp</strong> directory<br/>
```
    tar xvf newrelic-dotnet-buildpack-tile-*.tgz -C tmp
```

5. Change directory to <strong>tmp/packages</strong><br/>
```
    cd tmp/packages
```

6. Extract any of the individual buildpack <strong>.tgz</strong> files using the following command<br/>
```
    tar xvf <BUILDPACK_NAME>.tgz
```

this will create a folder by the name of the buildpack, and the newly created folder contains the zipped version of the buildpack. 

7. Upload the zipped buildpack file using CF CLI's <strong>"cf create-buildpack"</strong> command
```
    cf create-buildpack <BUILDPACK_NAME> <ZIPPED_BUILDPACK_NAME.zip> 99
```



<br/>


## <a id='buildpack-build-deploy'></a> Buildpack Build and Deploy Process


### <a id='build'></a> Build
The buildpacks in this tile are already built and ready to be used in Cloud Foundry. However, if you'd like to make changes to the buildpack, or update the cahced version of any buildpacks with newer version of dependencies, you could build your own copy. Please follow the instructions below to build your own copy of the buildpack(s):

1. Clone the buildpack repo to your system<br/>
``` 
git clone https://github.com/newrelic/newrelic-dotnetcore-extension-buildpack
or https://github.com/newrelic/newrelic-hwc-extension-buildpack
```

2. Change directory to the cloned buildpack

3. Source the <strong>.envrc</strong> file in the buildpack directory.
```
source .envrc
```

4. Install <strong>buildpack-packager</strong>
```
./scripts/install_tools.sh
```

5. Build the buildpack
```bash
buildpack-packager build [ --cached ] -any-stack
```


<br/>

### <a id='deploy'></a> Deploy

To deploy and use the buildpack in Cloud Foundry
Upload the buildpack to your Cloud Foundry and optionally specify it by name usinf CF CLI

```
cf create-buildpack [NEWRELIC_DOTNET_CORE_EXTENSION_BUILDPACK] [BUILDPACK_ZIP_FILE_PATH] 99
cf push my_app -b NEWRELIC_DOTNET_CORE_EXTENSION_BUILDPACK   -b DOTNET_CORE_BUILDPACK
```
<strong>Note:</strong> to create the HWC extension change the names from <strong>CORE</strong> to <strong>HWC</strong>.



<br/><br/><br/>
---
---
---
---
---
