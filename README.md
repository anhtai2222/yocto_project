# yocto_project

Yocto build setup for a **headless Raspberry Pi** (no monitor, no keyboard) —
the device auto-connects to Wi-Fi and accepts key-based SSH from the very first
boot.

The repo bundles the standard Yocto layers together with a small custom layer
(`meta-localcustom`) that pre-configures Wi-Fi and SSH into the rootfs at
image-build time.

## Requirements

- Linux build host (Ubuntu/Debian recommended) with the usual Yocto build
  dependencies.
- Release: **walnascar** (Yocto 5.2) — see `LAYERSERIES_COMPAT` in
  `meta-localcustom/conf/layer.conf`.

## Layout

```
.
├── poky/                 # Yocto/OpenEmbedded core (bitbake + meta)
├── meta-openembedded/    # Additional OpenEmbedded layers
├── meta-raspberrypi/     # Raspberry Pi BSP layer
└── meta-localcustom/     # Local custom layer (headless Wi-Fi + SSH)
    ├── conf/layer.conf
    └── classes/
        ├── wifi-preconfig.bbclass          # Wi-Fi via NetworkManager
        ├── wifi-preconfig-connman.bbclass  # Wi-Fi via ConnMan
        └── ssh-authorized-keys.bbclass     # Inject SSH public key
```

> `poky`, `meta-openembedded`, and `meta-raspberrypi` are pinned at fixed commits
> (see `git ls-tree HEAD`). All project-specific customization lives in
> `meta-localcustom`.

## Custom layer: `meta-localcustom`

This layer provides three bbclasses. To use them, `inherit` them in your image
recipe (or add `INHERIT`/`IMAGE_CLASSES` in `local.conf`) and set the variables
in `build/conf/local.conf`.

### 1. `wifi-preconfig` — Wi-Fi via NetworkManager

Drops a ready-made `.nmconnection` file into the rootfs so the device
auto-connects to Wi-Fi on first boot (WPA-PSK or open networks). It also sets the
cfg80211 regulatory domain.

Variables (override in `local.conf`):

| Variable       | Default                                | Meaning                              |
| -------------- | -------------------------------------- | ------------------------------------ |
| `WIFI_SSID`    | `KB-NOIBO`                             | Wi-Fi network name                   |
| `WIFI_PSK`     | `""`                                   | Password (`""` = open network)       |
| `WIFI_UUID`    | `5afb5c35-a423-4388-b147-eac4be1ffc97` | Any UUID4 for the NM connection      |
| `WIFI_COUNTRY` | `VN`                                   | Regulatory domain code (VN, US, JP…) |

### 2. `wifi-preconfig-connman` — Wi-Fi via ConnMan

The ConnMan equivalent, for images that run **ConnMan** instead of
NetworkManager. Writes a provisioning file at `/var/lib/connman/wifi.config`.
After the first successful connection, ConnMan stores the profile itself and
reconnects automatically on later boots.

Variables: `WIFI_SSID`, `WIFI_PSK`, `WIFI_COUNTRY` (same as above; this class
does not use `WIFI_UUID`).

> Pick **one** of the two Wi-Fi classes depending on the image's network manager
> — do not use both at the same time.

### 3. `ssh-authorized-keys` — key-based SSH login

Injects an SSH public key into `/home/root/.ssh/authorized_keys` so you can SSH
into the Pi by key, without a password.

| Variable          | Default                       | Meaning                              |
| ----------------- | ----------------------------- | ------------------------------------ |
| `SSH_PUBKEY_FILE` | `${HOME}/.ssh/id_ed25519.pub` | Path to the `.pub` file on the build host |

The build **fails** (`bbfatal`) if `SSH_PUBKEY_FILE` does not exist. This class
only injects the key; to disable password auth entirely you still need to harden
`sshd_config` separately.

## Build (quick start)

```sh
# 1. Initialize the build environment
source poky/oe-init-build-env build

# 2. Add the layers (edit build/conf/bblayers.conf), including meta-localcustom
bitbake-layers add-layer ../meta-localcustom

# 3. Configure build/conf/local.conf, e.g.:
#    MACHINE = "raspberrypi4-64"
#    INHERIT += "wifi-preconfig ssh-authorized-keys"
#    WIFI_SSID = "YourWifiName"
#    WIFI_PSK  = "YourWifiPassword"
#    SSH_PUBKEY_FILE = "/home/you/.ssh/id_ed25519.pub"

# 4. Build the image
bitbake core-image-base
```

After flashing the image to an SD card and powering the Pi, the device connects
to Wi-Fi and is ready for key-based SSH — no monitor or keyboard needed.

## Roadmap / Planned features

The following are planned and **not yet implemented**:

- **On-screen UI** — a local display interface shown on an attached screen
  (e.g. HDMI or a small panel) to surface device status and controls directly
  on the Pi.
- **Clean-shutdown handling** — graceful power-off / shutdown logic so the
  device powers down safely without corrupting the rootfs.
- **Additional custom layer recipes** — packaging the on-screen UI and shutdown
  service as recipes under `meta-localcustom`.
