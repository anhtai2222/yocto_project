# Inject a pre-configured NetworkManager Wi-Fi connection into the rootfs
# so the device auto-connects on first boot (headless setup).
#
# Variables (override in local.conf if needed):
#   WIFI_SSID     - Wi-Fi network name
#   WIFI_PSK      - Wi-Fi password ("" => open network)
#   WIFI_UUID     - any valid UUID4 string for the NM connection
#   WIFI_COUNTRY  - regulatory domain code, e.g. VN, US, JP

WIFI_SSID    ?= "KB-NOIBO"
WIFI_PSK     ?= ""
WIFI_UUID    ?= "5afb5c35-a423-4388-b147-eac4be1ffc97"
WIFI_COUNTRY ?= "VN"

inject_wifi_nmconnection() {
    install -d -m 0700 ${IMAGE_ROOTFS}${sysconfdir}/NetworkManager/system-connections
    nmfile=${IMAGE_ROOTFS}${sysconfdir}/NetworkManager/system-connections/${WIFI_SSID}.nmconnection

    if [ -z "${WIFI_PSK}" ]; then
        # Open network: omit [wifi-security] entirely
        cat > $nmfile <<EOF
[connection]
id=${WIFI_SSID}
uuid=${WIFI_UUID}
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=${WIFI_SSID}

[ipv4]
method=auto

[ipv6]
method=auto
EOF
    else
        cat > $nmfile <<EOF
[connection]
id=${WIFI_SSID}
uuid=${WIFI_UUID}
type=wifi
autoconnect=true

[wifi]
mode=infrastructure
ssid=${WIFI_SSID}

[wifi-security]
key-mgmt=wpa-psk
psk=${WIFI_PSK}

[ipv4]
method=auto

[ipv6]
method=auto
EOF
    fi
    chmod 0600 $nmfile

    # Regulatory domain for cfg80211 — set country for Wi-Fi radio
    install -d -m 0755 ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d
    echo "options cfg80211 ieee80211_regdom=${WIFI_COUNTRY}" \
        > ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d/cfg80211.conf
}

ROOTFS_POSTPROCESS_COMMAND += "inject_wifi_nmconnection;"
