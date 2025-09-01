@echo off
setlocal

set BUILD_DIR=%1
set CACHE_DIR=%2
set DEPS_DIR=%3
set DEPS_IDX=%4
set PROFILE_DIR=%5

set "BUILDPACK_DIR=%~dp0.."
call "%BUILDPACK_DIR%\scripts\install_go.bat"
if %errorlevel% neq 0 (
    echo Failed to install Go
    exit /b 1
)

set "output_dir=%TEMP%\finalize%RANDOM%"
mkdir "%output_dir%"

echo -----> Running go build finalize
set "GOPATH=%BUILDPACK_DIR%"
set "GOROOT=%TEMP%\go1.23.0\go"
set "GO_PROJECT_PATH=%BUILDPACK_DIR%\src\newrelic-hwc-extension\finalize\cli"

pushd "%GO_PROJECT_PATH%"
"%GOROOT%\bin\go.exe" build -o "%output_dir%\finalize.exe" .
popd

if not exist "%output_dir%\finalize.exe" (
    echo        **ERROR** Could not compile finalize binary
    exit /b 1
)

"%output_dir%\finalize.exe" "%BUILD_DIR%" "%CACHE_DIR%" "%DEPS_DIR%" "%DEPS_IDX%" "%PROFILE_DIR%"

REM Grant permissions to the newrelic directory to allow the profiler to be loaded.
echo -----> Setting permissions on New Relic agent directory
icacls "%BUILD_DIR%\newrelic" /grant "Users:(OI)(CI)F" /t

endlocal