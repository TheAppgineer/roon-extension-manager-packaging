#!/bin/bash
#
# Copyright 2017 The Appgineer
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Generic variables
NAME=roon-extension-manager
USR=$(env | grep SUDO_USER | cut -d= -f 2)

if [ -z "$USR" ]; then
    if [ $USER = "root" ]; then
        USR=root
    else
        echo "This script needs to run with root previleges" && exit 1
    fi
fi

USR_HOME=$(getent passwd "$USR" | cut -d: -f6)
GRP=$(getent passwd "$USR" | cut -d: -f4)
EXT_DIR=$USR_HOME/.RoonExtensions

# Check prerequisites
echo Checking prerequisites...

declare -a prereq=("systemctl" "git" "npm" "node")

## now loop through the above array
for i in "${prereq[@]}"
do
    "$i" --version > /dev/null 2>&1
    if [ $? -gt 0 ]; then
        echo Please install "$i"
        exit 1
    fi
done
echo "    OK"

# Configure npm
if [ ! -d "$EXT_DIR" ]; then
    mkdir "$EXT_DIR"
fi

PREFIX=$(npm config get prefix)

if [ "$PREFIX" != "$EXT_DIR" ]; then
    echo Configuring npm @ $EXT_DIR...

    echo prefix=$EXT_DIR > npmrc
    if [ ! -d "$PREFIX/etc" ]; then
        mkdir "$PREFIX/etc"
    fi
    mv npmrc $PREFIX/etc/
fi

# Install extensions
echo Installing extensions...

npm install -g https://github.com/TheAppgineer/$NAME.git
npm install -g https://github.com/TheAppgineer/$NAME-updater.git

# Download shell script
wget https://raw.githubusercontent.com/TheAppgineer/$NAME-packaging/master/linux/$NAME.sh

chmod +x $NAME.sh
mv $NAME.sh $EXT_DIR/lib/
chown -R $USR:$GRP $EXT_DIR

echo Setting up service...

# Create service file
cat << EOF > $NAME.service
[Unit]
Description=Roon Extension Manager
After=network.target

[Service]
User=$USR
Restart=always
WorkingDirectory=$EXT_DIR/lib
ExecStart=$EXT_DIR/lib/$NAME.sh
Environment="PATH=$PATH"

[Install]
WantedBy=multi-user.target
EOF

# Configure service
mv $NAME.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable $NAME

# Start service
systemctl start $NAME

echo
echo "Roon Extension Manager installed successfully!"
echo "Select Settings->Extensions on your Roon Remote to manage your extensions."
echo
