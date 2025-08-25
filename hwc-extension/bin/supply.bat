@echo off
REM filepath: /Users/gsidhwani/Documents/GitHub/PCF-Workspace/TAS6.0/newrelic-dotnet-buildpack-tile/hwc-extension/bin/supply.bat
setlocal

REM These variables are for reference; the script finds the path below.
set GO_VERSION=1.23.0
set GO_ZIP_FILENAME=go%GO_VERSION%.windows-amd64.zip

REM Define paths using the arguments provided by the buildpack runner. This is a writable location.
set GO_INSTALL_DIR=%3\%4\go_install
set GO_ZIP_FILE_PATH=%~dp0\..\dependencies\%GO_ZIP_FILENAME%
set SUPPLY_EXE_PATH=%3\%4\supply.exe
set BUILDPACK_DIR=%~dp0\..

echo ---  Go and New Relic Agent Setup ---
echo ---> Go will be installed in: %GO_INSTALL_DIR%

if not exist "%GO_ZIP_FILE_PATH%" (
    echo.
    echo *** FATAL: Packaged Go zip file not found at %GO_ZIP_FILE_PATH% ***
    echo.
    exit /b 1
)

echo ---> Found packaged Go. Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%GO_ZIP_FILE_PATH%' -DestinationPath '%GO_INSTALL_DIR%'"
if errorlevel 1 (
    echo.
    echo *** FAILED TO EXTRACT GO ***
    echo.
    exit /b 1
)

set GOROOT=%GO_INSTALL_DIR%\go
set PATH=%GOROOT%\bin;%PATH%

echo ---> Compiling New Relic supply executable...

REM Change to the Go module directory before building
pushd "%~dp0\..\src\newrelic-hwc-extension"

REM Build the CLI package and place the output in a writable location
go build -o "%SUPPLY_EXE_PATH%" ./supply/cli
set BUILD_ERROR=%errorlevel%

REM Return to the original directory
popd

if %BUILD_ERROR% neq 0 (
    echo.
    echo *** FAILED TO COMPILE SUPPLY EXECUTABLE ***
    echo.
    exit /b 1
)

echo --- Running New Relic Supply ---

REM Pass the original arguments AND the buildpack root path to the compiled Go program.
"%SUPPLY_EXE_PATH%" %1 %2 %3 %4 "%BUILDPACK_DIR%"