package supply

import (
	// "crypto/md5"
	"encoding/xml"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"

	"bytes"
	"encoding/json"
	"net/http"
	"regexp"
	"time"
	"errors"
	"crypto/sha256"
	"encoding/hex"

	"github.com/cloudfoundry/libbuildpack"
)


type Stager interface {
	//TODO: See more options at https://github.com/cloudfoundry/libbuildpack/blob/master/stager.go
	BuildDir() string
	DepDir() string
	DepsIdx() string
	DepsDir() string
	CacheDir() string
	WriteProfileD(string, string) error
	/* unused calls
	CacheDir() string
	LinkDirectoryInDepDir(string, string) error
	//AddBinDependencyLink(string, string) error
	WriteEnvFile(string, string) error
	WriteProfileD(string, string) error
	SetStagingEnvironment() error
	*/
}

type Manifest interface {
	//TODO: See more options at https://github.com/cloudfoundry/libbuildpack/blob/master/manifest.go
	AllDependencyVersions(string) []string
	DefaultVersion(string) (libbuildpack.Dependency, error)
}

type Installer interface {
	//TODO: See more options at https://github.com/cloudfoundry/libbuildpack/blob/master/installer.go
	InstallDependency(libbuildpack.Dependency, string) error
	InstallOnlyVersion(string, string) error
	/* unused calls
	FetchDependency(libbuildpack.Dependency, string) error
	*/
}

type Command interface {
	//TODO: See more options at https://github.com/cloudfoundry/libbuildpack/blob/master/command.go
	Execute(string, io.Writer, io.Writer, string, ...string) error
	Output(dir string, program string, args ...string) (string, error)
	/* unused calls
	Output(string, string, ...string) (string, error)
	*/
}

type Supplier struct {
	Manifest  Manifest
	Installer Installer
	Stager    Stager
	Command   Command
	Log       *libbuildpack.Logger
	/* unused calls
	Config    *config.Config
	Project   *project.Project
	*/
}


// for latest_release only - get latest version of the agent
const bucketXMLUrl              = "https://nr-downloads-main.s3.amazonaws.com/?delimiter=/&prefix=dot_net_agent/latest_release/"

// previous_releases contains all releases including latest
const latestNrDownloadUrl       = "http://download.newrelic.com/dot_net_agent/previous_releases/9.9.9.9/newrelic-netcore20-agent_9.9.9.9_amd64.tar.gz"
const latestNrDownloadSha256Url = "http://download.newrelic.com/dot_net_agent/previous_releases/9.9.9.9/SHA256/newrelic-netcore20-agent_9.9.9.9_amd64.tar.gz.sha256"

const nrVersionPattern          = "((\\d{1,3}\\.){3}\\d{1,3})" // regexp pattern to find agent version from urls
const newrelicAgentFolder       = "newrelic-netcore20-agent"
const newrelicProfilerSharedLib = "libNewRelicProfiler.so"

type bucketResultXMLNode struct {
	XMLName xml.Name
	Content []byte                `xml:",innerxml"`
	Nodes   []bucketResultXMLNode `xml:",any"`
}

var nrManifest struct {
	nrDownloadURL  string
	nrVersion      string
	nrDownloadFile string
	nrSha256Sum    string
}

// RULES for installing newrelic agent:
//	if:
//		- NEW_RELIC_LICENSE_KEY exists
//		- NEW_RELIC_DOWNLOAD_URL exists
//		- there is a user-provided-service with the word "newrelic" in the name
//		- there is a SERVICE in VCAP_SERVICES with the name "newrelic"
//		- for cached buildpack: nrDownloadFile from manifest is set to file name (non-blank)
//	then execute Run()



func (s *Supplier) Run() error {
	s.Log.BeginStep("Supplying Newrelic Dotnet Core Extension")

	s.Log.Debug("  >>>>>>> BuildDir: %s", s.Stager.BuildDir())
	s.Log.Debug("  >>>>>>> DepDir  : %s", s.Stager.DepDir())
	s.Log.Debug("  >>>>>>> DepsIdx : %s", s.Stager.DepsIdx())
	s.Log.Debug("  >>>>>>> DepsDir : %s", s.Stager.DepsDir())
	s.Log.Debug("  >>>>>>> CacheDir: %s", s.Stager.CacheDir())

	if NrServiceExists := detectNewRelicService(s); !NrServiceExists {
		s.Log.Info("No New Relic service to bind to...")
		return nil
	}

	s.Log.BeginStep("Installing NewRelic .Net Core Agent")

	buildpackDir, err := getBuildpackDir(s)
	if err != nil {
		s.Log.Error("Unable to install New Relic: %s", err.Error())
		return err
	}
	s.Log.Debug("buildpackDir: %v", buildpackDir)

	nrDownloadURL := latestNrDownloadUrl
	nrDownloadFile := ""
	nrVersion := "latest"
	nrSha256Sum := ""
	for _, entry := range s.Manifest.(*libbuildpack.Manifest).ManifestEntries {
		if entry.Dependency.Name == "newrelic" {
			nrDownloadURL = entry.URI
			nrVersion = entry.Dependency.Version
			nrDownloadFile = entry.File
			nrSha256Sum = entry.SHA256
		}
	}

	s.Log.BeginStep("Creating cache directory " + s.Stager.CacheDir())
	if err := os.MkdirAll(s.Stager.CacheDir(), 0755); err != nil {
		s.Log.Error("Failed to create cache directory "+s.Stager.CacheDir(), err)
		return err
	}


	//Begin: Download and Install
	//Approach 1: Recommended by Pivotal, but only works for fixed dependency version and URL specified in the manifest and checks shasum//
	/*
		// this approach is dependent on dependencies from manifest.yml file
		// we use different approaches to obtain the agent
		//	1 - NEW_RELIC_DOWNLOAD_URL env var
		//	2 - cached dependencies (use manifest dependency entries for caching)
		//	3 - version "latest" from manifest dependencies (figures out the latest and composes the URL)
		newrelicDependency := libbuildpack.Dependency{Name: "newrelic", Version: "7.1.229.0"}
		if err := s.Manifest.InstallDependency(newrelicDependency, s.Stager.DepDir()); err != nil {
			s.Log.Error("Error Installing  NewRelic Agent", err)
			return err
		}
	*/

	//Approach 2: Read download URL (folder portion only) and figure out the latest version


	s.Log.Debug("Installing NewRelic Agent -- Install (dep) directory: " + s.Stager.DepDir())

	// set temp directory for downloads
	s.Log.Debug("Creating tmp folder for downloading agent")
	tmpDir, err := ioutil.TempDir(s.Stager.DepDir(), "downloads")
	if err != nil {
		return err
	}
	nrDownloadLocalFilename := filepath.Join(tmpDir, "agent.tar.gz")

	// get agent version
	needToDownloadNrAgentFile := false
	if downloadURL, exists := os.LookupEnv("NEW_RELIC_DOWNLOAD_URL"); exists == true {
		nrDownloadURL = strings.TrimSpace(downloadURL)
		if sha256, exists := os.LookupEnv("NEW_RELIC_DOWNLOAD_SHA256"); exists == true {
			nrSha256Sum = sha256 // set by env var
		} else {
			nrSha256Sum = "" // ignore sha256 sum if not set by env var
		}
		needToDownloadNrAgentFile = true
	} else if nrDownloadFile != "" { // this file is cached by the buildpack
		s.Log.Info("Using cached dependencies...")
		source := nrDownloadFile
		if !filepath.IsAbs(source) {
			source = filepath.Join(buildpackDir, source)
		}
		s.Log.Debug("Copy [%s]", source)
		if err := libbuildpack.CopyFile(source, nrDownloadLocalFilename); err != nil {
			return err
		}
	} else {
		if (nrDownloadURL == "" || in_array(strings.ToLower(nrVersion), []string{"", "0.0.0.0", "latest", "current"})) {
			s.Log.Info("Obtaining latest agent version ")
			nrVersion, err = getLatestAgentVersion(s)
			if err != nil {
				s.Log.Error("Unable to obtain latest agent version from the metadata bucket", err)
				return err
			}
			s.Log.Debug("Latest agent version is " + nrVersion)

			// substitute agent version in the url
			updatedUrl, err := substituteUrlVersion(s, latestNrDownloadUrl, nrVersion)
			if err != nil {
				s.Log.Error("filed to substitute agent version in url")
				return err
			}
			nrDownloadURL = updatedUrl

			// read sha256 sum of the agent from NR download site
			latestNrAgentSha256Sum, err := getLatestNrAgentSha256Sum(s, tmpDir, nrVersion)
			if err != nil {
				s.Log.Error("Can't get SHA256 checksum for latest New Relic Agent download", err)
				return err
			}
			nrSha256Sum = latestNrAgentSha256Sum

		}
		needToDownloadNrAgentFile = true
	}

	if needToDownloadNrAgentFile {
		s.Log.BeginStep("Downloading New Relic agent...")
		if err := downloadDependency(s, nrDownloadURL, nrDownloadLocalFilename); err != nil {
			return err
		}
	}

	// compare sha256 sum of the downloaded file against expected sum
	if nrSha256Sum != "" {
		if err := checkSha256(nrDownloadLocalFilename, nrSha256Sum); err != nil {
			s.Log.Error("SHA256 checksum failed", err)
			return err
		}
	}

	// when dotnet core agent is extracted, it creates folder called  "newrelic-netcore20-agent"
	s.Log.BeginStep("Extracting NewRelic .Net Core Agent to %s", nrDownloadLocalFilename)
	if err := libbuildpack.ExtractTarGz(nrDownloadLocalFilename, s.Stager.DepDir()); err != nil {
		s.Log.Error("Error Extracting NewRelic .Net Core Agent", err)
		return err
	}
	// End: Download and Install

	// decide which newrelic.config file to use (appdir, buildpackdir, agentdir)
	if err := getNewRelicConfigFile(s, newrelicAgentFolder, buildpackDir); err != nil {
		return err
	}

	// // get Procfile - first check in app folder, if doesn't exisit check in buildpack dir
	// if err := getProcfile(s, buildpackDir); err != nil {
	// 	return err
	// }

	// build newrelic.sh in deps/IDX/profile.d folder
	if err := buildProfileD(s); err != nil {
		return err
	}

	s.Log.Info("Installing New Relic Agent Completed.")
	return nil
}




func detectNewRelicService(s *Supplier) bool {
	s.Log.Info("Detecting New Relic...")

	// check if the app requires to bind to new relic agent
	bindNrAgent := false
	if _, exists := os.LookupEnv("NEW_RELIC_LICENSE_KEY"); exists {
		bindNrAgent = true
	} else if _, exists := os.LookupEnv("NEW_RELIC_DOWNLOAD_URL"); exists {
		// must have license key in an NR service in VCAP_SERVICES or newrelic.config
		bindNrAgent = true
	} else {
		vCapServicesEnvValue := os.Getenv("VCAP_SERVICES")
		if vCapServicesEnvValue != "" {
			var vcapServices map[string]interface{}
			if err := json.Unmarshal([]byte(vCapServicesEnvValue), &vcapServices); err != nil {
		    	s.Log.Error("", err)
			} else {
		    	// check for a service from newrelic service broker (or tile)
				if _, exists := vcapServices["newrelic"].([]interface{}); exists {
					bindNrAgent = true
				} else {
			    	// check user-provided-services
					userProvidedServicesElement, _ := vcapServices["user-provided"].([]interface{})
			        for _, ups := range userProvidedServicesElement {
			        	s, _ := ups.(map[string]interface{})
			        	if exists := strings.Contains(strings.ToLower(s["name"].(string)), "newrelic"); exists {
			        		bindNrAgent = true
			        		break; 
						}
					}
				}
			}
		}
	}
	s.Log.Debug("Checked New Relic")
	s.Log.Debug("bindNrAgent: %v", bindNrAgent)
	return bindNrAgent
}

func getBuildpackDir(s *Supplier) (string, error) {
	// get the buildpack directory
	buildpackDir, err := libbuildpack.GetBuildpackDir()
	if err != nil {
		s.Log.Error("Unable to determine buildpack directory: %s", err.Error())
	}
	return buildpackDir, err
}

func in_array(searchStr string, array []string) bool {
    for _, v := range array {
        if  v == searchStr { // item found in array of strings
            return true
        }   
    }
    return false
}

func substituteUrlVersion(s *Supplier, url string, nrVersion string) (string, error) {
	s.Log.Debug("subsituting url version")
	nrVersionPatternMatcher, err := regexp.Compile(nrVersionPattern)
	if err != nil {
		s.Log.Error("filed to build rexexp pattern matcher")
		return "", err
	}
	result := nrVersionPatternMatcher.FindStringSubmatch(url)
	if (len(result) <= 0) {
		return "", errors.New("Error: no version match found in url")
	}
	uriVersion := result[1] // version pattern found in the url

	return strings.Replace(url, uriVersion, nrVersion, -1), nil
}

func getLatestNrAgentSha256Sum(s *Supplier, tmpDownloadDir string, latestNrVersion string) (string, error) {
	s.Log.Info("Obtaining Agent sha256 Sum from New Relic")
	shaUrl, err := substituteUrlVersion(s, latestNrDownloadSha256Url, latestNrVersion)
	if err != nil {
		s.Log.Error("filed to substitute agent version in sha256 url")
		return "", err
	}

	sha256File := filepath.Join(tmpDownloadDir, "nragent.sha256")
	if err := downloadDependency(s, shaUrl, sha256File); err != nil {
		return "", err
	}

	sha256Sum, err := ioutil.ReadFile(sha256File)
	if err != nil {
		return "", err
	}

	return strings.Split(string(sha256Sum), " ")[0], nil
}

func downloadDependency(s *Supplier, url string, filepath string) (err error) {
	s.Log.Debug("Downloading from [%s]", url)
	s.Log.Debug("Saving to [%s]", filepath)

	var httpClient = &http.Client{
		Timeout: time.Second * 10,
	}

	// Create the file
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	// Get the data
	resp, err := httpClient.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Check server response
	if resp.StatusCode != http.StatusOK {
		return errors.New("bad status: " + resp.Status)
	}

	// Writer the body to file
	_, err = io.Copy(out, resp.Body)
	if err != nil {
		return err
	}

	return nil
}

func checkSha256(filePath, expectedSha256 string) error {
	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}

	sum := sha256.Sum256(content)

	actualSha256 := hex.EncodeToString(sum[:])

	if strings.ToLower(actualSha256) != strings.ToLower(expectedSha256) {
		return errors.New("dependency sha256 mismatch: expected sha256: " + expectedSha256 + ", actual sha256: " + actualSha256)
	}
	return nil
}

func getNewRelicConfigFile(s *Supplier, newrelicDir string, buildpackDir string) error {
	newrelicConfigBundledWithApp := filepath.Join(s.Stager.BuildDir(), "newrelic.config")
	newrelicConfigDest := filepath.Join(s.Stager.DepDir(), newrelicDir, "newrelic.config")
	newrelicConfigBundledWithAppExists, err := libbuildpack.FileExists(newrelicConfigBundledWithApp)
	if err != nil {
		s.Log.Error("Unable to test existence of newrelic.config in app folder", err)
		newrelicConfigBundledWithAppExists = false
	}
	if newrelicConfigBundledWithAppExists {
		// newrelic.config exists in app folder
		s.Log.Info("Using newrelic.config provided in the app folder")
		s.Log.Debug("Copying %s to %s", newrelicConfigBundledWithApp, newrelicConfigDest)
		if err := libbuildpack.CopyFile(newrelicConfigBundledWithApp, newrelicConfigDest); err != nil {
			s.Log.Error("Error Copying newrelic.config provided within the app folder", err)
			return err
		}
	} else {
		// check if newrelic.config exists in the buildpack folder
		newrelicConfigBundledWithBuildPack := filepath.Join(buildpackDir, "newrelic.config")
		newrelicConfigFileExists, err := libbuildpack.FileExists(newrelicConfigBundledWithBuildPack)
		if err != nil {
			s.Log.Error("Error checking if newrelic.confg exists in buildpack", err)
			return err
		}
		if newrelicConfigFileExists {
			// newrelic.config exists in buidpack folder
			s.Log.Info("Using newrelic.config provided with the buildpack")
			if err := libbuildpack.CopyFile(newrelicConfigBundledWithBuildPack, newrelicConfigDest); err != nil {
				s.Log.Error("Error copying newrelic.config provided by the buildpack", err)
				return err
			}
			s.Log.Info("Overwriting newrelic.config template provided with the buildpack")
		} else {
			s.Log.Info("Using default newrelic.config downloaded with the agent")
		}
	}
	return nil
}

func getProcfile(s *Supplier, buildpackDir string) error {
	procFileBundledWithApp := filepath.Join(s.Stager.BuildDir(), "Procfile")
	procFileBundledWithAppExists, err := libbuildpack.FileExists(procFileBundledWithApp)
	if err != nil {
		// no Procfile found in the app folder
		procFileBundledWithAppExists = false
	}
	if procFileBundledWithAppExists {
		// Procfile exists in app folder
		s.Log.Debug("Using Procfile provided in the app folder")
	} else {
		s.Log.Debug("No Procfile found in the app folder")
		// looking for Procfile in the buildpack dir
		procFileBundledWithBuildPack := filepath.Join(buildpackDir, "Procfile")
		procFileDest := filepath.Join(s.Stager.BuildDir(), "Procfile")
		procFileBundledWithBuildPackExists, err := libbuildpack.FileExists(procFileBundledWithBuildPack)
		if err != nil {
			s.Log.Error("Error checking if Procfile exists in buildpack", err)
			return err
		}
		if procFileBundledWithBuildPackExists {
			// Procfile exists in buidpack folder
			s.Log.Debug("Using Procfile provided with the buildpack")
			if err := libbuildpack.CopyFile(procFileBundledWithBuildPack, procFileDest); err != nil {
				s.Log.Error("Error copying Procfile provided by the buildpack", err)
				return err
			}
			s.Log.Debug("Copied Procfile from buildpack to app folder")
		} else {
			s.Log.Debug("No Procfile provided by the buildpack")
		}
	}
	return nil
}

func buildProfileD(s *Supplier) error {
	var profileDScriptContentBuffer bytes.Buffer

	s.Log.Info("Enabling New Relic Dotnet Core Profiler")
	// build deps/IDX/profile.d/newrelic.sh
	profileDScriptContentBuffer = setNewRelicProfilerProperties(s)

	// search criteria for app name and license key in ENV, VCAP_APPLICATION, VCAP_SERVICES
	// order of precedence
	//		1 env vars
	//		2 user-provided-service
	//		3 serevice broker instance
	//
	// always look in UPS credentials for other values that might be set (i.e. distributed tracing)

	newrelicAppName := ""
	newrelicLicenseKey := ""
	newrelicDistributedTracing := ""

	newrelicAppName = parseVcapApplicationEnv(s)

	// NEW_RELIC_LICENSE_KEY env var always overwrites other license keys
	if _, exists := os.LookupEnv("NEW_RELIC_LICENSE_KEY"); exists == false {
		vCapServicesEnvValue := os.Getenv("VCAP_SERVICES")
		if vCapServicesEnvValue == "" {
			s.Log.Warning("Please make sure New Relic License Key is defined by \"setting env var\", or using \"user-provided-service\", \"service broker service instance\", or \"newrelic.config file\"")
			// s.Log.Warning("Please set New Relic license key by setting environment variable, or binding to a New Relic service instance / user-provided-service")
			// return errors.New("Error: No New Relic License Key found in the environment!")
		} else {
			var vcapServices map[string]interface{}
			if err := json.Unmarshal([]byte(vCapServicesEnvValue), &vcapServices); err != nil {
		    	s.Log.Error("", err)
			} else {
				newrelicLicenseKey = parseNewRelicService(s, vcapServices)
				appName, licenseKey, distributedTracing := parseUserProvidedServices(s, vcapServices, newrelicAppName, newrelicLicenseKey, newrelicDistributedTracing)
				newrelicAppName = appName
				newrelicLicenseKey = licenseKey
				newrelicDistributedTracing = distributedTracing
			}
		}
	}

	if newrelicAppName != "" {
		profileDScriptContentBuffer.WriteString(strings.Join([]string{"export NEW_RELIC_APP_NAME=", newrelicAppName}, ""))
		profileDScriptContentBuffer.WriteString("\n")
	}

	if newrelicLicenseKey != "" {
		profileDScriptContentBuffer.WriteString(strings.Join([]string{"export NEW_RELIC_LICENSE_KEY=", newrelicLicenseKey}, ""))
		profileDScriptContentBuffer.WriteString("\n")
	}

	if newrelicDistributedTracing != "" {
		profileDScriptContentBuffer.WriteString(strings.Join([]string{"export NEW_RELIC_DISTRIBUTED_TRACING_ENABLED=", newrelicDistributedTracing}, ""))
		profileDScriptContentBuffer.WriteString("\n")
	}

	profileDScript := profileDScriptContentBuffer.String()
	return s.Stager.WriteProfileD("newrelic.sh", profileDScript)
}

// build deps/IDX/profile.d/newrelic.sh
func setNewRelicProfilerProperties(s *Supplier) bytes.Buffer {
	var profilerSettingsBuffer bytes.Buffer

	profilerSettingsBuffer.WriteString(filepath.Join("export CORECLR_NEWRELIC_HOME=$DEPS_DIR", s.Stager.DepsIdx(), newrelicAgentFolder))
	profilerSettingsBuffer.WriteString("\n")
	profilerSettingsBuffer.WriteString(filepath.Join("export CORECLR_PROFILER_PATH=$DEPS_DIR", s.Stager.DepsIdx(), newrelicAgentFolder, newrelicProfilerSharedLib))
	profilerSettingsBuffer.WriteString("\n")
	profilerSettingsBuffer.WriteString("export CORECLR_ENABLE_PROFILING=1")
	profilerSettingsBuffer.WriteString("\n")
	profilerSettingsBuffer.WriteString("export CORECLR_PROFILER={36032161-FFC0-4B61-B559-F6C5D41BAE5A}")
	profilerSettingsBuffer.WriteString("\n")
	return profilerSettingsBuffer
}

func parseVcapApplicationEnv(s *Supplier) string {
	newrelicAppName := ""
	// NEW_RELIC_APP_NAME env var always overwrites other app names
	if _, exists := os.LookupEnv("NEW_RELIC_APP_NAME"); exists == false {
		vCapApplicationEnvValue := os.Getenv("VCAP_APPLICATION")
		var vcapApplication map[string]interface{}
		if err := json.Unmarshal([]byte(vCapApplicationEnvValue), &vcapApplication); err != nil {
			s.Log.Error("Unable to unmarshall VCAP_APPLICATION environment variable, NEW_RELIC_APP_NAME will not be set in profile script", err)
		} else {
			appName, ok := vcapApplication["application_name"].(string)
			if ok {
				s.Log.Info("VCAP_APPLICATION.application_name=" + appName)
				newrelicAppName = appName
			}
		}
	} else {
		newrelicAppName = ""
	}
	return newrelicAppName
}

func parseNewRelicService(s *Supplier, vcapServices map[string]interface{}) string {
	newrelicLicenseKey := ""
	// check for a service from newrelic service broker (or tile)
	newrelicElement, ok := vcapServices["newrelic"].([]interface{})
	if ok {
  		if len(newrelicElement) > 0 {
    		newrelicMap, ok := newrelicElement[0].(map[string]interface{})
    		if ok {
      			credMap, ok := newrelicMap["credentials"].(map[string]interface{})
      			if ok {
        			newrelicLicense, ok := credMap["licenseKey"].(string)
        			if ok {
          				// s.Log.Info("VCAP_SERVICES.newrelic.credentials.licenseKey=" + "**Redacted**")
          				newrelicLicenseKey = newrelicLicense
        			}
      			}
    		}
  		}
	}
	return newrelicLicenseKey
}

func parseUserProvidedServices(s *Supplier, vcapServices map[string]interface{}, newrelicAppName string, newrelicLicenseKey string, newrelicDistributedTracing string) (string, string, string) {
	// check user-provided-services
	userProvidesServicesElement, _ := vcapServices["user-provided"].([]interface{})
    for _, ups := range userProvidesServicesElement {
    	element, _ := ups.(map[string]interface{})
    	if found := strings.Contains(strings.ToLower(element["name"].(string)), "newrelic"); found == true {
			cmap, _ := element["credentials"].(map[string]interface{})
        	for key, cred := range cmap {
        		if (in_array(strings.ToLower(key), []string{"license_key", "licensekey", "new_relic_license_key"})) {
        			newrelicLicenseKey = cred.(string) // license key from user-provided-service -- overwrites license key from service broker
					s.Log.Debug("VCAP_SERVICES." + element["name"].(string) + ".credentials." + key + "=" + "**redacted**") //newrelicLicenseKey)
				} else if (in_array(strings.ToLower(key), []string{"appname", "app_name", "new_relic_app_name"})) {
					newrelicAppName = cred.(string) // application name from user-provided-service -- overwrites name from service broker
					s.Log.Info("VCAP_SERVICES." + element["name"].(string) + ".credentials." + key + "=" + newrelicAppName)
				} else if (in_array(strings.ToLower(key), []string{"distributedtracing", "distributed_tracing", "new_relic_distributed_tracing", "new_relic_distributed_tracing_enabled"})) {
					// NEW_RELIC_DISTRIBUTED_TRACING_ENABLED
					newrelicDistributedTracing = cred.(string) // NEW_RELIC_DISTRIBUTED_TRACING_ENABLED
					s.Log.Info("VCAP_SERVICES." + element["name"].(string) + ".credentials." + key + "=" + newrelicDistributedTracing)
				}
			}
		}
	}
	return newrelicAppName, newrelicLicenseKey, newrelicDistributedTracing
}

func getLatestAgentVersion(s *Supplier) (string, error) {
	latestAgentVersion := ""
	resp, err := http.Get(bucketXMLUrl)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	// Check server response
	if resp.StatusCode != http.StatusOK {
		return "", errors.New("Bad http status when downloading XML meta data: " + resp.Status)
	}

	data, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	buf := bytes.NewBuffer(data)
	dec := xml.NewDecoder(buf)

	var listBucketResultNode bucketResultXMLNode
	err = dec.Decode(&listBucketResultNode)
	if err != nil {
		return "", err
	}

	for _, nc := range listBucketResultNode.Nodes {
		if nc.XMLName.Local == "Contents" {
			key := ""
			for _, nc2 := range nc.Nodes {
				if nc2.XMLName.Local == "Key" {
					key = string(nc2.Content)
					break
				}
			}
			nrVersionPatternMatcher, err := regexp.Compile(nrVersionPattern)
			if err != nil {
				return "", err
			}

			result := nrVersionPatternMatcher.FindStringSubmatch(key)
			if len(result) > 1 {
				latestAgentVersion = result[1]
			}
		}
	}
	return latestAgentVersion, nil
}
