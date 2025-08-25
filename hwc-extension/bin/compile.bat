REM filepath: hwc-extension/bin/compile.bat
@echo off
setlocal

set BUILD_DIR=%1
set CACHE_DIR=%2
set BUILDPACK_PATH=%~dp0.
set DEPS_DIR=%BUILD_DIR%\.cloudfoundry

mkdir "%CACHE_DIR%" > nul 2>&1
mkdir "%DEPS_DIR%\0" > nul 2>&1
mkdir "%BUILD_DIR%\.profile.d" > nul 2>&1

echo export DEPS_DIR=$HOME/.cloudfoundry > "%BUILD_DIR%\.profile.d\0000_set-deps-dir.sh"

call "%BUILDPACK_PATH%\supply.bat" "%BUILD_DIR%" "%CACHE_DIR%" "%DEPS_DIR%" 0
call "%BUILDPACK_PATH%\finalize.bat" "%BUILD_DIR%" "%CACHE_DIR%" "%DEPS_DIR%" 0

endlocal