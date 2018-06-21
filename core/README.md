# New Relic .Net Core Agent Buildpack for PCF
The New Relic .Net Core Agent buildpack is built as an extension buildpack for standard dotnet core buildpack.

Use this buildpack along with the dotnet core buildpack to automatically install the New Relic .Net Core agent during application deployment.

The buildpack is create during the tile installation, so there is no need to separately install it using 'cf create-buildpack'.

You can bind to New Relic dotnet core agent in one of the following ways:
* use **"newrelic.config"** file with application name and your account's license key specified

* if you have **"New Relic agent tile"** deployed in your PCF, bind to one of the service plans in the service broker

* set environment variables **"NEW_RELIC_LICENSE_KEY"** and **"NEW_RELIC_APP_NAME"** in the application environment

Note: Environment variables **"NEW_RELIC_LICENSE_KEY"** and **"NEW_RELIC_APP_NAME"** overwrite the license key from **newrelic.config**

To use New Relic dotnet core buildpack in **disconnected** (isolated) environments you can do the following:
* download the **".tgz"** file version of the latest New Relic dotnet core agent from [New Relic Download Site][a]
* upload the agent **".tgz"** file to your internal repository and make note of the url to it
* use **"NEW_RELIC_DOWNLOAD_URL"** environment variable and set its value to url from previous step in your internal repository.
* restage your application

Push the application using v3 version of CF CLI push (**"cf v3-push"**). The v3 version is needed for pushing extension buildpacks with Dotnet Core buildpack.

* **cf v3-push my_app -b NEWRELIC_BUILDPACK_NAME  -b DOTNET_CORE_2.0_BUILDPACK_NAME**

Make sure New Relic extension buildpack is specified first. This command will first run the New Relic .Net Core build pack to install the .Net Core Agent and then runs the main .Net Core 2.0 build pack to install the .Net Core SDK and deploy the application.

[a]: http://download.newrelic.com/dot_net_agent/latest_release/