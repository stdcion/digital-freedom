#!/bin/sh

# Configuration defaults
DEFAULT_HOSTNAME="Routerich"
DEFAULT_ROUTER_IP="192.168.1.1"
DEFAULT_ROOT_PASS="toor"
DEFAULT_WIFI_SSID="Routerich"
DEFAULT_WIFI_KEY="12345678"
DEFAULT_DISABLE_LED="no"

# Initialize variables
HOSTNAME="${DEFAULT_HOSTNAME}"
ROUTER_IP="${DEFAULT_ROUTER_IP}"
ROOT_PASS="${DEFAULT_ROOT_PASS}"
WIFI_SSID="${DEFAULT_WIFI_SSID}"
WIFI_KEY="${DEFAULT_WIFI_KEY}"
DISABLE_LED="${DEFAULT_DISABLE_LED}"

# Logging
LOG_FILE="/tmp/router_config.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

validate_ip() {
    echo "$1" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' || {
        log "Invalid IP address: $1"
        exit 1
    }
}

validate_wifi_key() {
    [ ${#1} -ge 8 ] || {
        log "WiFi key must be at least 8 characters"
        exit 1
    }
}

config_hostname() {
    log "Setting hostname..."
    uci set system.@system[0].hostname="${HOSTNAME}"
    uci commit system
    service system restart
}

config_https_access() {
    log "Setting HTTPS access..."
    uci set uhttpd.main.redirect_https='1' 
    uci commit uhttpd
    service uhttpd reload
}

config_root_pass() {
    log "Setting root password..."
    ubus call luci setPassword '{"username":"root", "password":"'"${ROOT_PASS}"'"}'
}

config_router_ip() {
    log "Configuring router IP..."    
    uci set network.lan.ipaddr="${ROUTER_IP}"
    uci commit network
}

config_offloading() {
    log "Configuring offloading..."
    uci set network.globals.packet_steering='1'
    uci set firewall.@defaults[0].flow_offloading='1'
    uci set firewall.@defaults[0].flow_offloading_hw='1'
    uci commit firewall
    uci commit network
}

config_ntp() {
    log "Configuring NTP..."
    uci set system.@system[0].timezone='MSK-3'
    uci set system.@system[0].zonename='Europe/Moscow'
    uci set system.ntp.enabled='1'
    uci set system.ntp.enable_server='0'
    uci delete system.ntp.server
    uci add_list system.ntp.server='216.239.35.0'
    uci add_list system.ntp.server='216.239.35.4'
    uci add_list system.ntp.server='216.239.35.8'
    uci add_list system.ntp.server='216.239.35.12'
    uci add_list system.ntp.server='162.159.200.123'
    uci add_list system.ntp.server='162.159.200.1'
    uci commit
    service sysntpd restart
    service system restart
}

config_wifi() {
    log "Configuring WiFi..."
    
    # 2.4GHz
    uci set wireless.radio0.channel='6'
    uci set wireless.radio0.htmode='HE40'
    uci set wireless.radio0.country='PA'
    uci set wireless.radio0.txpower='26'
    uci set wireless.radio0.cell_density='0'
    uci set wireless.radio0.disabled='0'
    uci set wireless.default_radio0.network='lan'
    uci set wireless.default_radio0.ssid="${WIFI_SSID}"_2
    uci set wireless.default_radio0.encryption='sae-mixed'
    uci set wireless.default_radio0.key="${WIFI_KEY}"
    uci set wireless.default_radio0.ocv='0'

    # 5GHz
    uci set wireless.radio1.channel='36'
    uci set wireless.radio1.htmode='HE80'
    uci set wireless.radio1.country='PA'
    uci set wireless.radio1.txpower='27'
    uci set wireless.radio1.cell_density='0'
    uci set wireless.radio1.disabled='0'
    uci set wireless.default_radio1.network='lan'
    uci set wireless.default_radio1.ssid="${WIFI_SSID}"_5
    uci set wireless.default_radio1.encryption='sae-mixed'
    uci set wireless.default_radio1.key="${WIFI_KEY}"
    uci set wireless.default_radio1.ocv='0'
    
    uci commit wireless
}

disable_ipv6() {
    log "Disabling IPv6..."
    uci set 'network.lan.ipv6=0'
    uci set 'network.wan.ipv6=0'
    uci set 'dhcp.lan.dhcpv6=disabled'
    uci -q delete dhcp.lan.dhcpv6
    uci -q delete dhcp.lan.ra
    uci set network.lan.delegate="0"
    uci -q delete network.globals.ula_prefix

    /etc/init.d/odhcpd stop
    /etc/init.d/odhcpd disable

    sysctl -w net.ipv6.conf.all.disable_ipv6=1
    echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
    sysctl -w net.ipv6.conf.default.disable_ipv6=1
    sysctl -w net.ipv6.conf.lo.disable_ipv6=1

    uci set dhcp.@dnsmasq[0].filter_aaaa='1'

    sed -i '/^net.ipv6.conf.all.disable_ipv6=/d' /etc/sysctl.conf
    sed -i '/^net.ipv6.conf.default.disable_ipv6=/d' /etc/sysctl.conf
    sed -i '/^net.ipv6.conf.lo.disable_ipv6=/d' /etc/sysctl.conf
    echo "net.ipv6.conf.all.disable_ipv6=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.lo.disable_ipv6=1" >> /etc/sysctl.conf

    sysctl -p
    uci commit
    sed -i '/::1/d' /etc/resolv.conf
    service dnsmasq restart
}

config_button() {
    mkdir -p /etc/hotplug.d/button
    cat << "EOF" > /etc/hotplug.d/button/00-button
    source /lib/functions.sh

    do_button () {
        local button
        local action
        local handler
        local min
        local max

        config_get button "${1}" button
        config_get action "${1}" action
        config_get handler "${1}" handler
        config_get min "${1}" min
        config_get max "${1}" max

        [ "${ACTION}" = "${action}" -a "${BUTTON}" = "${button}" -a -n "${handler}" ] && {
            [ -z "${min}" -o -z "${max}" ] && eval ${handler}
            [ -n "${min}" -a -n "${max}" ] && {
                [ "${min}" -le "${SEEN}" -a "${max}" -ge "${SEEN}" ] && eval ${handler}
            }
        }
    }

    config_load system
    config_foreach do_button button
EOF
}

get_user_input() {
    read -r -p "Enter Hostname [${HOSTNAME}]: " input
    [ -n "$input" ] && HOSTNAME="$input"

    read -r -p "Enter Router IP [${ROUTER_IP}]: " input
    [ -n "$input" ] && ROUTER_IP="$input"
    validate_ip "$ROUTER_IP"

    read -r -p "Enter root password [${ROOT_PASS}]: " input
    [ -n "$input" ] && ROOT_PASS="$input"

    read -r -p "Enter WiFi SSID [${WIFI_SSID}]: " input
    [ -n "$input" ] && WIFI_SSID="$input"

    read -r -p "Enter WiFi Key [${WIFI_KEY}]: " input
    [ -n "$input" ] && WIFI_KEY="$input"
    validate_wifi_key "$WIFI_KEY"
}

main() {
    log "Starting router configuration..."
    get_user_input
    
    config_ntp
    config_offloading
    disable_ipv6
    config_hostname
    config_root_pass
    config_wifi
    config_router_ip
    config_https_access
    config_button
    
    log "Configuration completed!"
    echo "Changes logged to $LOG_FILE"
    
    read -r -p "Reboot now? [y/N]: " choice
    case "$choice" in
        [yY]*) reboot ;;
        *) echo "Reboot manually to apply changes" ;;
    esac
    reload_config
}

main
