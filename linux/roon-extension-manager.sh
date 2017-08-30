#!/bin/sh
cd node_modules/roon-extension-manager
node . ignore service > /dev/null

if [ $? -eq 66 ]; then
    cd ../roon-extension-manager-updater
    node . > /dev/null
fi

cd ../..
