# Inject a pre-configured ConnMan Wi-Fi service into the rootfs
# so the device auto-connects on first boot (headless setup).
#
# ConnMan đọc file provisioning ở /var/lib/connman/*.config với cú pháp:
#   [service_<id>]
#   Type = wifi
#   Name = <SSID>
#   Passphrase = <PSK>      # bỏ dòng này nếu mạng mở
#
# Sau lần đầu nối thành công, ConnMan tự lưu profile trong cùng thư mục
# và tự reconnect ở các lần boot sau.
#
# Variables (override in local.conf if needed):
#   WIFI_SSID     - Wi-Fi network name
#   WIFI_PSK      - Wi-Fi password ("" => open network, bỏ Passphrase)
#   WIFI_COUNTRY  - regulatory domain code, e.g. VN, US, JP

WIFI_SSID    ?= "KB-NOIBO"
WIFI_PSK     ?= ""
WIFI_COUNTRY ?= "VN"

inject_wifi_connman_config() {
    install -d -m 0700 ${IMAGE_ROOTFS}${localstatedir}/lib/connman
    cfgfile=${IMAGE_ROOTFS}${localstatedir}/lib/connman/wifi.config

    # Sanitize SSID thành service id (chỉ giữ chữ/số/dấu gạch dưới)
    svcid=$(echo "${WIFI_SSID}" | tr -c 'A-Za-z0-9_' '_')

    if [ -z "${WIFI_PSK}" ]; then
        # Open network: không có Passphrase
        cat > $cfgfile <<EOF
[global]
Name = ${WIFI_SSID}
Description = Pre-configured Wi-Fi for headless boot

[service_${svcid}]
Type = wifi
Name = ${WIFI_SSID}
EOF
    else
        cat > $cfgfile <<EOF
[global]
Name = ${WIFI_SSID}
Description = Pre-configured Wi-Fi for headless boot

[service_${svcid}]
Type = wifi
Name = ${WIFI_SSID}
Passphrase = ${WIFI_PSK}
EOF
    fi
    chmod 0600 $cfgfile

    # Regulatory domain cho cfg80211 — set country cho Wi-Fi radio
    install -d -m 0755 ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d
    echo "options cfg80211 ieee80211_regdom=${WIFI_COUNTRY}" \
        > ${IMAGE_ROOTFS}${sysconfdir}/modprobe.d/cfg80211.conf
}

ROOTFS_POSTPROCESS_COMMAND += "inject_wifi_connman_config;"
