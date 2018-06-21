# HWC Buildpack modified with New Relic Agent Install
This buildpack modified the hwc_buildpack to add instructions to download and install New Relic agent.

## How to Install the Buildpack
* Open nr-hwc-buildpack-v2.3.16nr4.tgz in a separate folder

* Create Buildpack in PCF using 'cf create-buildpack'. Run the following command:

	cf create-buildpack nr-hwc-buildpack ./hwc_buildpack-v2.3.16nr2.zip 1

* Verify that the buildpack is created. You should see nr-hwc-buildpack when the following command is executed.
    cf buildpacks 


## How to Use the Buildpack

This buildpack supports application binding both directly using environment variables and also by using New Relic's Agent Tile. In both cases if you need to customize New Relic agent's configuration, you would need to provide your own 'newrelic.config' file by copying it to your application folder before pushing the application.


### Using New Relic Agent Tile

In order to bind to a pre-existing New Relic account which is already associated with one of the plans in New Relic tile, you can bind your application to New Relic dotNet agent in one of the following ways:

* Bind your application to New Relic using the Agent Tile in the Marketplace
	- click on New Relic tile in the Marketplace
	- create an instance of the service for the plan that is associated with your target New Relic account
	- use "services" section in your manifest.yml file, and specify the name of the service you just created in the marketplace
	- "restage" the application

* Bind your application to New Relic using AppMgr
	- Push your application to PCF
	- In AppMgr click on your application
	- goto "Service" tab of your application
	- If you have already created a service instance from the tile, select "Bind Service". If this is the first time and you have not created any service instances, select "New Service"
	- Follow the instructions to create a new service or bind to an existing service
	- "restage" the application

* Bind your application to New Relic using User-Provided-Service
	- Create 1 user-provided-service with "newrelic" included in the service name 
	- add the following credentials to the user-rpovided-service:
		- "licenseKey" This is New Relic License Key - REQUIRED
		- "appName"    If you want to change the app name in New Relic use this property - OPTIONAL
	- push your application one of the following ways:
		- by adding the user-provided-service to the manifest before pushing the app
		- by adding the user-provided-service in AppMgr and restaging it after you add the service.


### Using Environment Variables or "newrelic.config" file

* You can use combination of "newrelic.config" file and/or environment variables to configure New Relic dotNet agent ro report your application health to your New Relic account.

	- A copy of the 'newrelic.config' file is provided with the buildpack kit. If you need to add any agent features such as proxy settings, or change any other agent settings such as logging behavior, copy this file (or provide your copy) into the application folder, and edit as required. The following are some examplles you can use:

		- add your New Relic license key:
			  <service licenseKey="9999999999999999999999999999999999999999">
		
			alternatively you can add the license key to application's 'manifest.yml' file as an environment variable "NEW_RELIC_LICENSE_KEY" in the "env" section


		- add the New Relic application name as you'd like it to appear in New Relic
			  <application>
			    <name>My Application</name>
			  </application>

			alternatively you can add the New Relic app name to application's 'manifest.yml' file as an environment variable "NEW_RELIC_APP_NAME" in the "env" section


	    - add proxy settings to the "service" tag as an element. example:
	    	  <service licenseKey="9999999999999999999999999999999999999999">
	    	    <proxy host="my_proxy_server.com" port="9090" />
	    	  </service>


	    - change agent logging level and destination
	    	  <log level="info" console="true" />

	    - as 'hwc.exe' is the executable running your application, make sure 'newrelic.config' contains the following tag:
			  <instrumentation>
			    <applications>
			      <application name="hwc.exe" />
			    </applications>
			  </instrumentation>

	    
	    Note:  Depending on your CI/CD pipeline, the Application directory may be created on-the-fly as part of the pipeline.  If that is the case, your pipeline will need to copy over this file to the Application directory before deploying/pushing the app to PCF.

	 
	- Push your application to PCF using this buildpack. To do that, edit your manifest.yml and add/update the following entry.

		buildpack: nr-hwc-buildpack

		Then run "cf push".

		Note: If this is CI/CD (aka Bamboo), the "cf push" may not be required as your pipeline internally uses "cf push" to push the application to PCF.


* Check the logs. 

	Use 'cf logs <APP_NAME>' to examine the logs. It should display New Relic agent installation progress.  It should also log the environment "set" commands.

* If there is no direct internet connection for downloading the New Relic agent, you might have to manually download the newrelic agent from http://download.newrelic.com/dot_net_agent/latest_release/newrelic-agent-win-x64-8.2.216.0.zip (or the latest zipped version of the agent) and host it locally in your network. Then specify your internal location as an ENV variable - "NEW_RELIC_DOWNLOAD_URL"

