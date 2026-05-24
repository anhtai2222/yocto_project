# Inject SSH public key vào /home/root/.ssh/authorized_keys của rootfs
# để SSH login bằng key, không cần password.
#
# Variables (override trong local.conf):
#   SSH_PUBKEY_FILE  - đường dẫn file .pub trên máy build (vd ~/.ssh/id_ed25519.pub)
#
# Sau khi class này chạy, trên Pi sẽ có:
#   /home/root/.ssh/                 (mode 0700, owner root)
#   /home/root/.ssh/authorized_keys  (mode 0600, owner root)
#
# Lưu ý: lớp này CHỈ inject key. Muốn cấm hẳn password auth thì sửa
# sshd_config riêng (xem ROOTFS_POSTPROCESS hardening trong local.conf).

SSH_PUBKEY_FILE ?= "${HOME}/.ssh/id_ed25519.pub"

inject_ssh_authorized_key() {
    if [ ! -f "${SSH_PUBKEY_FILE}" ]; then
        bbfatal "SSH_PUBKEY_FILE không tồn tại: ${SSH_PUBKEY_FILE}"
    fi

    install -d -m 0700 ${IMAGE_ROOTFS}/home/root/.ssh
    install -m 0600 "${SSH_PUBKEY_FILE}" \
        ${IMAGE_ROOTFS}/home/root/.ssh/authorized_keys

    # /home/root thường thuộc root:root mode 0700 trong Yocto rồi,
    # nhưng đảm bảo .ssh và authorized_keys đúng chủ sở hữu sau khi rootfs build.
    chown -R 0:0 ${IMAGE_ROOTFS}/home/root/.ssh
}

ROOTFS_POSTPROCESS_COMMAND += "inject_ssh_authorized_key;"
