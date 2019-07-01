#!/bin/bash
#
# Copyright 2017, 2018, 2019 The Appgineer
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
VERSION=0.5.2
NAME=roon-extension-manager
USR=$(env | grep SUDO_USER | cut -d= -f 2)
MIN_NODE_VERSION=8

echo $NAME setup script - version $VERSION
echo

if [ "$1" = "--version" ]; then
    exit 0
fi

if [ -z "$USR" ]; then
    USR=`whoami`

    if [ "$USR" != "root" ]; then
        if [ "$SVC" = "" ]; then
            echo "Root privileges are required to setup the service!"
            echo "Do you want to install without service setup? (y/N)"
            read ANSWER

            if [ "$ANSWER" = "y" ]; then
                SVC=0
            else
                exit 0
            fi
        fi
    fi
fi

if [ "$SVC" = "" ]; then
    SVC=1
fi

USR_HOME=$(getent passwd "$USR" | cut -d: -f6)
GRP=$(getent passwd "$USR" | cut -d: -f4)
EXT_DIR=$USR_HOME/.RoonExtensions

if [ "$1" = "--uninstall" ]; then
    if [ "$SVC" = "1" ]; then
        # Remove service
        systemctl stop $NAME
        systemctl disable $NAME
        rm /etc/systemd/system/$NAME.service
    fi

    # Remove files
    rm `npm config ls -l | grep ^globalconfig | awk '{split($0,a,"\""); print a[2]}'`
    rm -rf "$EXT_DIR"

    exit 0
fi

# Check prerequisites
echo Checking prerequisites...
declare -a prereq=("git" "npm" "node")

if [ "$SVC" = "1" ]; then
    prereq+=("systemctl")
fi

if [ ! -f "$NAME.sh" ]; then
    prereq+=("wget")
fi

## Now loop through the above array
for i in "${prereq[@]}"
do
    VERSION=$("$i" --version 2> /dev/null)
    if [ $? -gt 0 ]; then
        echo Please install "$i"
        exit 1
    elif [ "$i" = "node" ]; then
        # Perform minimum version check for node
        if [ "${VERSION:2:1}" = "." ]; then
            VERSION=${VERSION:1:1}
        else
            VERSION=${VERSION:1:2}
        fi
        if [ "$VERSION" -lt "$MIN_NODE_VERSION" ]; then
            echo Please install "$i" version "$MIN_NODE_VERSION".x or higher
            exit 1
        fi
    fi
done
echo "    OK"

mkdir -p "$EXT_DIR"/{etc,lib,bin}

# Configure npm
if [ ! -d "$EXT_DIR" ]; then
    chown -R $USR:$GRP $EXT_DIR
fi

if [ -f "$USR_HOME/.npmrc" ]; then
    # Hide user settings
    mv $USR_HOME/.npmrc $USR_HOME/.npmrc.bak
fi

PREFIX=$(npm config get prefix)

if [ "$PREFIX" != "$EXT_DIR" ]; then
    echo Configuring npm @ $EXT_DIR...

    echo prefix=$EXT_DIR > npmrc

    if [ "$SVC" = "1" ]; then
        if [ ! -d "$PREFIX/etc" ]; then
            mkdir "$PREFIX/etc"
        fi
        mv npmrc $PREFIX/etc/
    else
        mv npmrc "$USR_HOME/.npmrc"
    fi

    if [ $? -gt 0 ]; then
        exit 1
    fi
fi

# Install extensions
echo Installing extensions...

if [ "$SVC" = "1" ]; then
    su -c "npm install -g https://github.com/TheAppgineer/$NAME.git" $USR
    su -c "npm install -g https://github.com/TheAppgineer/$NAME-updater.git" $USR
else
    npm install -g https://github.com/TheAppgineer/$NAME.git
    npm install -g https://github.com/TheAppgineer/$NAME-updater.git
fi

if [ ! -f "$NAME.sh" ]; then
    # Download shell script
    wget https://raw.githubusercontent.com/TheAppgineer/$NAME-packaging/master/linux/$NAME.sh
fi

chmod +x $NAME.sh
mv $NAME.sh $EXT_DIR/bin/
if [ $? -gt 0 ]; then
    exit 1
fi

if [ "$SVC" = "1" ]; then
    if [ ! -f "/etc/systemd/system/$NAME.service" ]; then
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
ExecStart=$EXT_DIR/bin/$NAME.sh
Environment="PATH=$PATH"

[Install]
WantedBy=multi-user.target
EOF

        # Configure service
        mv $NAME.service /etc/systemd/system/
        if [ $? -gt 0 ]; then
            exit 1
        fi
        systemctl daemon-reload
    fi

    systemctl enable $NAME

    # Start service
    systemctl start $NAME
fi

echo
echo "Roon Extension Manager installed successfully!"
echo "Select Settings->Extensions on your Roon Remote to manage your extensions."
echo
