A comprehensive solution for configuring OpenWrt-based routers to enable transparent proxy routing with domain-based filtering, supporting various services like Discord, YouTube and etc.

## Project Overview

This project combines and enhances several open-source solutions to create a robust network configuration for OpenWrt routers, featuring:

- Transparent proxy routing with TPROXY
- Fake IP DNS implementation
- Domain and IP-based filtering
- Automatic rule-set generation
- Simplified management via shell scripts

## Key Components

### 1. freedomctl
The main control script that manages:
- Transparent proxy routing rules (nftables)
- Fake IP DNS configuration
- Service integration (Sing-box)
- Domain-based filtering for various services

### 2. Domain Lists
- Predefined domain lists for common services
- Personal domain filtering lists
- Automatic conversion to Sing-box compatible rule-sets

### 3. Router Configuration
- Initial setup scripts for OpenWrt routers
- WiFi, firewall, and network optimization
- IPv6 disablement for better compatibility

## Features

- **Transparent Proxy Routing**:
  - Uses nftables for efficient packet handling
  - Supports both TCP and UDP traffic
  - Marks packets for TPROXY handling

- **Domain Filtering**:
  - Predefined rules for popular services
  - Customizable personal domain lists
  - Automatic updates from community sources

- **Fake IP DNS**:
  - Prevents DNS leaks
  - Improves connection performance
  - Works with Sing-box implementation

- **Easy Management**:
  - Start/stop/restart functionality
  - Toggle feature for quick enable/disable
  - Automatic initialization

## Credits

This project builds upon the work of several open-source projects:

- [vernette/singbox-tproxy-fakeip](https://github.com/vernette/singbox-tproxy-fakeip) - Core transparent proxy and FakeIP configuration
- [itdoginfo/podkop](https://github.com/itdoginfo/podkop) - Reference configuration and routing logic
- [itdoginfo/allow-domains](https://github.com/itdoginfo/allow-domains) - Community-maintained domain lists and subnets
- [Davoyan/router-xray-fakeip-installation](https://github.com/Davoyan/router-xray-fakeip-installation) - Router configuration
