#!/bin/sh

rm 32/setup.7z
rm 64/setup.7z
rm xp/setup.7z

7za a 32/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./32/os-vars.bat ./32/nssm.exe ./32/curl.exe
7za a 64/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./64/os-vars.bat ./64/nssm.exe ./64/curl.exe
7za a xp/setup.7z setup.bat roon-extension-manager.bat cacert.pem ./xp/os-vars.bat ./xp/nssm.exe ./xp/curl.exe

cat 7zSD.sfx config.txt 32/setup.7z > 32/setup-win32-$1.exe
cat 7zSD.sfx config.txt 64/setup.7z > 64/setup-win64-$1.exe
cat 7zSD.sfx config.txt xp/setup.7z > xp/setup-winxp-$1.exe
