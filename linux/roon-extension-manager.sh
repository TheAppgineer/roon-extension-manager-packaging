#!/bin/sh
cd node_modules/roon-extension-manager
node . $1

if [ $? -eq 66 ]; then
    cd ../roon-extension-manager-updater
    node .
fi

cd ../..
