@echo off
setlocal
echo [install_go.bat] Script started.

set GO_VERSION=1.23.0
set "GoInstallDir=%TEMP%\go%GO_VERSION%"
echo [install_go.bat] GoInstallDir is %GoInstallDir%

echo [install_go.bat] Checking if Go is already installed...
if exist "%GoInstallDir%\go\bin\go.exe" (
    echo [install_go.bat] Go is already installed. Exiting successfully.
    exit /b 0
)
echo [install_go.bat] Go not found. Proceeding with installation.

echo [install_go.bat] Creating directory %GoInstallDir%
mkdir "%GoInstallDir%"

set GO_SHA256=d4be481ef73079ee0ad46081d278923aa3fd78db1b3cf147172592f73e14c1ac
set URL=https://go.dev/dl/go%GO_VERSION%.windows-amd64.zip
echo [install_go.bat] Download URL is %URL%

echo [install_go.bat] Attempting to download go %GO_VERSION% with PowerShell...
powershell -Command "[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'; $webClient = New-Object System.Net.WebClient; $webClient.Headers.Add('User-Agent', 'Mozilla/5.0'); $webClient.DownloadFile('%URL%', '%TEMP%\go.zip')"
echo [install_go.bat] PowerShell download command finished.

echo [install_go.bat] Checking if go.zip exists...
if not exist "%TEMP%\go.zip" (
    echo [install_go.bat] **FATAL** Could not download go zip file.
    exit /b 1
)
echo [install_go.bat] go.zip was downloaded successfully.

echo [install_go.bat] Verifying SHA256 checksum...
powershell -Command "if ((Get-FileHash -Path '%TEMP%\go.zip' -Algorithm SHA256).Hash.ToLower() -ne '%GO_SHA256%') { exit 1 }"
if %errorlevel% neq 0 (
    echo [install_go.bat] **FATAL** SHA256 mismatch for downloaded file.
    del "%TEMP%\go.zip"
    exit /b 1
)
echo [install_go.bat] SHA256 checksum is correct.

echo [install_go.bat] Extracting Go archive...
powershell -Command "Expand-Archive -Path '%TEMP%\go.zip' -DestinationPath '%GoInstallDir%'"
echo [install_go.bat] Extraction command finished.

del "%TEMP%\go.zip"

echo [install_go.bat] Verifying go.exe exists after extraction...
if not exist "%GoInstallDir%\go\bin\go.exe" (
    echo [install_go.bat] **FATAL** Could not find go.exe after extraction.
    exit /b 1
)

echo [install_go.bat] Script finished successfully.
endlocal