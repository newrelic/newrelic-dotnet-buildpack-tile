# New Relic .Net Core Agent Buildpack for PCF
The New Relic .Net Core Agent build pack is built as a multi-buildpack packaged as a zip file
(nr_netcore_buildpack-v*.*.*.zip). Use this buildpack along with the dotnet-core-buildpack to
automatically install the New Relic .Net Core during application deployment.
Create the build pack
cf create-buildpack **NEWRELIC_BUILDPACK_NAME** **BUILDPACK_ZIP_FILE_PATH** 1

Ensure the newrelic.config file is updated with the NEWRELIC_LICENSE_KEY and APPLICA-
TION_NAME and placed in the application folder.

If [NEW_RELIC_LICENSE_KEY] is found in the environment, it would overwrite other forms of license keys that have been provided (i.e. license key from newrelic.config).

Push the application using v3 version of cloud foundry push (**"cf v3-push"**). The v3 version is needed for pushing extension buildpacks with Dotnet Core buildpack.

cf v3-push my_app [-b NEWRELIC_BUILDPACK_NAME] [-b DOTNET_CORE_2.0_BUILDPACK_NAME]

This command will first run the New Relic .Net Core build pack to install the .Net Core Agent
and then runs the main .Net Core 2.0 build pack to install the .Net Core SDK and deploy the
application.
