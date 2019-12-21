#!/bin/sh

mkdir -p downloads
cd downloads

if ! [ -f nssm-2.24.zip ]; then
    curl -LO https://nssm.cc/release/nssm-2.24.zip
fi

if ! [ -f curl-7.67.0_5-win32-mingw.zip ]; then
    curl -LO https://curl.haxx.se/windows/dl-7.67.0_5/curl-7.67.0_5-win32-mingw.zip
fi

if ! [ -f curl-7.67.0_5-win64-mingw.zip ]; then
    curl -LO https://curl.haxx.se/windows/dl-7.67.0_5/curl-7.67.0_5-win64-mingw.zip
fi

curl -LO https://curl.haxx.se/ca/cacert.pem
curl -LO https://github.com/git-for-windows/build-extra/raw/master/7-Zip/7zSD.sfx

cd ..
7za e downloads/nssm-2.24.zip -o32/ -aoa nssm-2.24/win32/nssm.exe
7za e downloads/nssm-2.24.zip -o64/ -aoa nssm-2.24/win64/nssm.exe
7za e downloads/curl-7.67.0_5-win32-mingw.zip -o32/ -aoa curl-7.67.0-win32-mingw/bin/curl.exe
7za e downloads/curl-7.67.0_5-win64-mingw.zip -o64/ -aoa curl-7.67.0-win64-mingw/bin/curl.exe

rm 32/setup.7z
rm 64/setup.7z

7za a 32/setup.7z setup.bat roon-extension-manager.bat ./downloads/cacert.pem ./32/os-vars.bat ./32/nssm.exe ./32/curl.exe
7za a 64/setup.7z setup.bat roon-extension-manager.bat ./downloads/cacert.pem ./64/os-vars.bat ./64/nssm.exe ./64/curl.exe

cat downloads/7zSD.sfx config.txt 32/setup.7z > 32/setup-win32-$1.exe
cat downloads/7zSD.sfx config.txt 64/setup.7z > 64/setup-win64-$1.exe
