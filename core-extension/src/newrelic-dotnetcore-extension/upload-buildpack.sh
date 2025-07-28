# First, check buildpack order:
cf buildpacks
cf delete-buildpack newrelic-dotnet-extension-buildpack
cf buildpacks

# Assume dotnet-core_buildpack is at position 2 or higher.
# Let's try to put our newrelic buildpack at position 1.
cf create-buildpack newrelic-dotnet-extension-buildpack ~/newrelic-dotnet-extension.zip 1 --enable
cf buildpacks
