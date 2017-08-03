#!/bin/sh

7za a 32/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./32/nssm.exe ./32/curl.exe
7za a xp/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./xp/nssm.exe ./xp/curl.exe
7za a 64/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./64/nssm.exe ./64/curl.exe

cat 7zS.sfx 32/config.txt 32/setup.7z > 32/setup-win32.exe
cat 7zS.sfx xp/config.txt xp/setup.7z > xp/setup-winxp.exe
cat 7zS.sfx 64/config.txt 64/setup.7z > 64/setup-win64.exe
