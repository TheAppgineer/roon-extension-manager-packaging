@echo off

rem Copyright 2017, 2018, 2019 The Appgineer
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

setlocal enabledelayedexpansion

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

nssm status %NAME% > nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Stopping service...
    nssm stop %NAME%
    echo.
)

rem Install Node.js
call :is_installed "%INSTALL_DIR%\nodejs\node.exe" %NODE_VERSION%
if %ERRORLEVEL% EQU 0 goto :git

if not exist "%DL_DIR%\%NODE%" (
    call :action "Downloading %NODE%..."    "%CURL% %DL_DIR%\%NODE% %NODE_URL%"
    if !ERRORLEVEL! NEQ 0 goto :error
)

call :action "Installing Node.js..."    "%MSIEXEC% %DL_DIR%\%NODE%"             "sync"
if %ERRORLEVEL% NEQ 0 goto :error

:git
rem Install Git
call :is_installed "%INSTALL_DIR%\Git\cmd\git.exe" %GIT_VERSION%
if %ERRORLEVEL% EQU 0 goto :configure

if not exist "%DL_DIR%\%GIT%" (
    call :action "Downloading %GIT%..."     "%CURL% %DL_DIR%\%GIT% %GIT_URL%"
    if !ERRORLEVEL! NEQ 0 goto :error
)

call :action "Installing git..."        "%DL_DIR%\%GIT% %GIT_OPTIONS%"          "sync"
if %ERRORLEVEL% NEQ 0 goto :error

:configure
rem Configure npm
if not exist "%EXT_DIR%" (
    mkdir "%EXT_DIR%"
)

rem Update path for the active environment
git --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    set "Path=%Path%;%INSTALL_DIR%\Git\cmd"
)

node --version > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    set "Path=%Path%;%INSTALL_DIR%\nodejs;%AppData%\npm"
)

rem Set NPM_CONFIG_PREFIX
if NOT "%NPM_CONFIG_PREFIX%" == "EXT_DIR" (
    echo Configuring npm...
    set NPM_CONFIG_PREFIX=%EXT_DIR:\=/%
    setx NPM_CONFIG_PREFIX "%EXT_DIR:\=/%" -m
)

rem Remove old installation
if exist "%EXT_DIR%\node_modules\%NAME%" (
    call :action "Removing old installation..." "npm uninstall -g %NAME%"
    RMDIR /S /Q "%EXT_DIR%\node_modules\%NAME%"
)

if exist "%EXT_DIR%\node_modules\%NAME%-updater" (
    call :action "Removing old installation..." "npm uninstall -g %NAME%-updater"
    RMDIR /S /Q "%EXT_DIR%\node_modules\%NAME%-updater"
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

rem Functions
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

:is_installed
set "file=%~1"
if not defined file goto :not_installed
if not exist "%file%" goto :not_installed

set "version="
FOR /F "tokens=2 delims==" %%a in ('
    wmic datafile where name^="%file:\=\\%" get Version /value
') do set "version=%%a"

call set replaced=%%version:%2=%%

IF not "%replaced%"=="%version%" (
    exit /b 0
)

:not_installed
exit /b 1
