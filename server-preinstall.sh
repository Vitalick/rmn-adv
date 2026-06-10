#!/usr/bin/env bash
set -eu

REMOTE_INSTALLER_URL="https://github.com/DigneZzZ/remnawave-scripts/raw/main/remnanode.sh"
SCRIPT_URL="https://raw.githubusercontent.com/Vitalick/rmn-adv/refs/heads/main/server-preinstall.sh"

need_root() {
    if [ "$(id -u)" -eq 0 ]; then
        return
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "Run this script as root: sudo bash $0" >&2
        exit 1
    fi

    echo "Root privileges are required. Re-running with sudo..." >&2
    script_source="$(download_self)"
    exec sudo bash -c "$script_source"
}

download_self() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$SCRIPT_URL"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$SCRIPT_URL"
    else
        echo "Install curl or wget before running this script." >&2
        exit 1
    fi
}

read_public_key() {
    echo "Paste your SSH public key below, then press Enter:" >&2
    printf "> " >&2
    IFS= read -r public_key

    if [ -z "$public_key" ]; then
        echo "Public key is empty, aborting." >&2
        exit 1
    fi

    case "$public_key" in
        ssh-rsa\ *|ssh-ed25519\ *|ecdsa-sha2-nistp256\ *|ecdsa-sha2-nistp384\ *|ecdsa-sha2-nistp521\ *)
            ;;
        *)
            echo "Input does not look like a supported SSH public key." >&2
            exit 1
            ;;
    esac

    printf "%s\n" "$public_key"
}

install_authorized_key() {
    public_key="$1"
    ssh_dir="$HOME/.ssh"
    authorized_keys="$ssh_dir/authorized_keys"

    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    touch "$authorized_keys"

    if grep -qxF "$public_key" "$authorized_keys"; then
        echo "Public key is already present in $authorized_keys"
    else
        printf "%s\n" "$public_key" >> "$authorized_keys"
        echo "Public key added to $authorized_keys"
    fi

    chmod 600 "$authorized_keys"
}

configure_sshd() {
    if [ -d /etc/ssh/sshd_config.d ]; then
        hardening_file="/etc/ssh/sshd_config.d/99-disable-password-auth.conf"
        cat > "$hardening_file" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
UsePAM no
EOF
        echo "Wrote SSH hardening config to $hardening_file"
    else
        config_file="/etc/ssh/sshd_config"
        cp "$config_file" "$config_file.bak.$(date +%Y%m%d%H%M%S)"

        set_sshd_option "$config_file" "PasswordAuthentication" "no"
        set_sshd_option "$config_file" "KbdInteractiveAuthentication" "no"
        set_sshd_option "$config_file" "ChallengeResponseAuthentication" "no"
        set_sshd_option "$config_file" "UsePAM" "no"
        echo "Updated SSH hardening options in $config_file"
    fi
}

set_sshd_option() {
    file="$1"
    option="$2"
    value="$3"

    if grep -Eq "^[#[:space:]]*$option[[:space:]]+" "$file"; then
        sed -i "s|^[#[:space:]]*$option[[:space:]].*|$option $value|" "$file"
    else
        printf "\n%s %s\n" "$option" "$value" >> "$file"
    fi
}

restart_sshd() {
    if command -v sshd >/dev/null 2>&1; then
        sshd -t
    elif [ -x /usr/sbin/sshd ]; then
        /usr/sbin/sshd -t
    else
        echo "Cannot find sshd binary for config validation." >&2
        exit 1
    fi

    if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
        systemctl restart ssh
    elif systemctl list-unit-files sshd.service >/dev/null 2>&1; then
        systemctl restart sshd
    else
        service ssh restart 2>/dev/null || service sshd restart
    fi

    echo "sshd config is valid and service was restarted."
}

install_remnanode() {
    if command -v curl >/dev/null 2>&1; then
        bash <(curl -Ls "$REMOTE_INSTALLER_URL") @ install
    elif command -v wget >/dev/null 2>&1; then
        bash <(wget -qO- "$REMOTE_INSTALLER_URL") @ install
    else
        echo "Install curl or wget before installing remnanode." >&2
        exit 1
    fi
}

main() {
    need_root
    public_key="$(read_public_key)"
    install_authorized_key "$public_key"
    configure_sshd
    restart_sshd
    install_remnanode
}

main "$@"
