A comprehensive solution for configuring OpenWrt-based routers to enable transparent proxy routing with domain and IP-based filtering, supporting various services like Discord, YouTube and etc.

This project is intended for **research and educational purposes only**.

## Project Overview

This project combines several open-source solutions to create a network configuration for OpenWrt routers, featuring:

- Transparent proxy
- Fake IP
- Domain and IP-based filtering
- Automatic rule-set update
- Simplified management via shell scripts

## Key Components

### 1. freedomctl
The core control utility for managing transparent proxy functionality.

#### Key Features:
- Controls sing-box service
- Manages nftables routing rules
- Handles FakeIP DNS configuration
- Automatic rule-set update

#### Usage:
```bash
./freedomctl init      # Initial system setup (after reboot)
./freedomctl start     # Enable proxy (sets up routing and starts services)
./freedomctl stop      # Disable proxy (cleans up rules and stops services)
./freedomctl restart   # Full proxy restart (stop + start)
./freedomctl toggle    # Switch between enabled/disabled states
```

sh <(wget -O - https://raw.githubusercontent.com/stdcion/digital-freedom/master/devices/routerich-ax3000/firstboot.sh)
sh <(wget -O - https://raw.githubusercontent.com/stdcion/digital-freedom/master/devices/routerich-ax3000/install_freedom.sh)


The `toggle` function is useful to bind to a physical button to quickly enable/disable the proxy.

### 2. Router Configuration
The `devices` directory contains scripts for initial initializing the router and installing the sing-box.

The configuration includes:
- Initial setup scripts for OpenWrt routers
- WiFi, firewall, and network configuration
- Disabling IPv6 for better compatibility

### 2. Domain Lists
- Predefined domain lists for common services
- Personal domain filtering lists
- Automatic conversion to Sing-box compatible rule-sets

## Credits

This project builds upon the work of several open-source projects:

- [vernette/singbox-tproxy-fakeip](https://github.com/vernette/singbox-tproxy-fakeip) - Core transparent proxy and FakeIP configuration
- [itdoginfo/podkop](https://github.com/itdoginfo/podkop) - Reference configuration and routing logic
- [itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains) - Community-maintained domain lists and subnets
- [Davoyan/router-xray-fakeip-installation](https://github.com/Davoyan/router-xray-fakeip-installation) - Router configuration
