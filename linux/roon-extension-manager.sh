#!/bin/bash

# Background info: http://veithen.io/2014/11/16/sigterm-propagation.html

# Setup signal handlers
_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM "$child"
}

_int() {
  echo "Caught SIGINT signal!"
  kill -INT "$child"
}

trap _term SIGTERM
trap _int  SIGINT

# Start Roon Extension Manager
cd node_modules/roon-extension-manager
node . $1 &

# Wait for termination
child=$!
wait "$child"       # Extra wait in case released by a trap
wait "$child"

if [ $? -eq 66 ]; then
    # Handle update request
    cd ../roon-extension-manager-updater
    node . &

    # Wait for termination
    child=$!
    wait "$child"   # Extra wait in case released by a trap
    wait "$child"
fi

cd ../..
