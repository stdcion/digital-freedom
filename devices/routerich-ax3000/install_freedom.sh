#!/bin/sh

GITHUB_RAW_URL="https://raw.githubusercontent.com/stdcion/digital-freedom/master/"
FREEDOM_URL="${GITHUB_RAW_URL}/freedomctl"
FREEDOM_PATH=/usr/bin/freedomctl
SING_BOX_CONFIG_URL="${GITHUB_RAW_URL}/sing-box/config.json"
SING_BOX_CONFIG_PATH="/etc/sing-box/config.json"

# We need the right time
service sysntpd restart

# Install dependencies
opkg update && opkg install sing-box kmod-nft-tproxy kmod-button-hotplug 

# Set button configuration
uci add system button
uci set system.@button[-1].name='proxy_toggle'
uci set system.@button[-1].button='BTN_0'
uci set system.@button[-1].action="released"
uci set system.@button[-1].min="1"
uci set system.@button[-1].max="5"
uci set system.@button[-1].handler="$FREEDOM_PATH toggle"
uci set system.@button[-1].enabled='1'
uci commit system

# Download freedom
wget -O $FREEDOM_PATH $FREEDOM_URL
chmod +x $FREEDOM_PATH

# Add to startup
sed -i "/exit 0/i sh $FREEDOM_PATH init" /etc/rc.local

# Download sing-box config
wget -O $SING_BOX_CONFIG_PATH $SING_BOX_CONFIG_URL

echo "