@echo off

cd node_modules\roon-extension-manager
node . ignore service

if %ERRORLEVEL% EQU 66 (
    cd ..\roon-extension-manager-updater
    node .
)

cd ..\..
