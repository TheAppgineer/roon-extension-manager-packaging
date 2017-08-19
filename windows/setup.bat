@echo off

rem Copyright 2017 The Appgineer
rem
rem Licensed under the Apache License, Version 2.0 (the "License");
rem you may not use this file except in compliance with the License.
rem You may obtain a copy of the License at
rem
rem     http://www.apache.org/licenses/LICENSE-2.0
rem
rem Unless required by applicable law or agreed to in writing, software
rem distributed under the License is distributed on an "AS IS" BASIS,
rem WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
rem See the License for the specific language governing permissions and
rem limitations under the License.

rem Generic variables
set NAME=roon-extension-manager
set DL_DIR=dl
set EXT_DIR=%AppData%\RoonExtensions

set CURL=curl.exe --cacert cacert.pem --progress-bar --location --output
set MSIEXEC=msiexec.exe /passive /norestart /package
set GIT_OPTIONS="/SILENT /NORESTART"

call os-vars.bat

set NODE_URL=https://nodejs.org/download/release/v%NODE_VERSION%/%NODE%
set GIT_URL=https://github.com/git-for-windows/git/releases/download/v%GIT_VERSION%.windows.1/%GIT%

rem Create download directory
if not exist "%DL_DIR%" (
    mkdir %DL_DIR%
)

rem Download installers
if not exist "%DL_DIR%\%NODE%" (
    call :action "Downloading %NODE%..."    "%CURL% %DL_DIR%\%NODE% %NODE_URL%"
    if %ERRORLEVEL% NEQ 0 goto :error
)

if not exist "%DL_DIR%\%GIT%" (
    call :action "Downloading %GIT%..."     "%CURL% %DL_DIR%\%GIT% %GIT_URL%"
    if %ERRORLEVEL% NEQ 0 goto :error
)

rem Install prerequisites
if not exist "%INSTALL_DIR%\nodejs\npm" (
    call :action "Installing Node.js..."    "%MSIEXEC% %DL_DIR%\%NODE%"             "sync"
    if %ERRORLEVEL% NEQ 0 goto :error
)

if not exist "%INSTALL_DIR%\Git\cmd\git.exe" (
    call :action "Installing git..."        "%DL_DIR%\%GIT% %GIT_OPTIONS%"          "sync"
    if %ERRORLEVEL% NEQ 0 goto :error
)

rem Configure npm
if not exist "%EXT_DIR%" (
    mkdir "%EXT_DIR%"
)

git --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    set "Path=%Path%;%INSTALL_DIR%\nodejs;%INSTALL_DIR%\Git\cmd;%AppData%\npm"
)

if "%NPM_CONFIG_PREFIX%" == "" (
    echo Configuring npm...
    set NPM_CONFIG_PREFIX=%EXT_DIR:\=/%
    setx NPM_CONFIG_PREFIX "%EXT_DIR:\=/%" -m
)

rem Install extension
call :action "Installing Roon Extension Manager..." "npm install -g https://github.com/TheAppgineer/%NAME%.git"
if %ERRORLEVEL% NEQ 0 goto :error

call :action "Installing Updater..." "npm install -g https://github.com/TheAppgineer/%NAME%-updater.git"
if %ERRORLEVEL% NEQ 0 goto :error

rem Configure service
nssm status %NAME% > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Configuring service...
    copy /b /y nssm.exe "%NPM_CONFIG_PREFIX%" > nul
    copy /b /y roon-extension-manager.bat "%NPM_CONFIG_PREFIX%" > nul
    cd "%NPM_CONFIG_PREFIX:/=\%"
    nssm install %NAME% roon-extension-manager.bat
    nssm set %NAME% DisplayName "Roon Extension Manager"
    nssm set %NAME% AppDirectory "%NPM_CONFIG_PREFIX%"
    nssm set %NAME% AppStdout nul
    nssm set %NAME% AppStderr "%NPM_CONFIG_PREFIX%\%NAME%.log"
    nssm set %NAME% AppEnvironmentExtra APPDATA="%AppData%" "PATH=%Path%"
)

rem Start service
echo.
echo Starting service...
nssm start %NAME%
if %ERRORLEVEL% NEQ 0 goto :error

echo.
echo Roon Extension Manager installed successfully!
echo Select Settings-^>Extensions on your Roon Remote to manage your extensions.
echo.

rem Force execution to quit now that we reached the end of the "main" logic
:error
pause
exit /B %ERRORLEVEL%

:action
echo %~1

if "%3" == "sync" (
    start /wait %~2
) else (
    %~2
)

if %ERRORLEVEL% EQU 0 (
    echo     OK
) else (
    echo     FAILED with return code: %ERRORLEVEL%
)
echo.

exit /b %ERRORLEVEL%
