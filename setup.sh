#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Hyprland dotfiles installer for Arch Linux
# Description:
#   - Installs required packages
#   - Copies dotfiles config/ into ~/.config
#   - Creates backups of existing configuration
#   - Enables required services
#   - Reboots the system automatically
###############################################################################

# -----------------------------------------------------------------------------
# Logging helpers
# -----------------------------------------------------------------------------
log() {
    printf "[INFO] %s\n" "$1"
}

warn() {
    printf "[WARN] %s\n" "$1"
}

error() {
    printf "[ERROR] %s\n" "$1" >&2
    exit 1
}

# -----------------------------------------------------------------------------
# Privilege check
# -----------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root."
fi

# -----------------------------------------------------------------------------
# Path definitions
# -----------------------------------------------------------------------------
DOTFILES_DIR="$(pwd)"
SOURCE_CONFIG_DIR="$DOTFILES_DIR/config"
TARGET_CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d_%H%M%S)"

# -----------------------------------------------------------------------------
# Sanity checks
# -----------------------------------------------------------------------------
if [[ ! -d "$SOURCE_CONFIG_DIR" ]]; then
    error "config/ directory not found in dotfiles repository."
fi

# -----------------------------------------------------------------------------
# yay installation
# -----------------------------------------------------------------------------
install_yay() {
    if command -v yay >/dev/null 2>&1; then
        log "yay is already installed."
        return
    fi

    log "Installing yay..."
    sudo pacman -S --needed --noconfirm git base-devel

    tmpdir="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"
    (
        cd "$tmpdir/yay"
        makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
}

# -----------------------------------------------------------------------------
# Package definitions
# -----------------------------------------------------------------------------
PACMAN_PKGS=(
    bluez
    blueman
    networkmanager
    gvfs
    libnotify
    neovim
    python-pywal
)

YAY_PKGS=(
    hyprland
    waybar
    hyprpicker
    swaync
    wofi
    wlogout
    starship
)

# -----------------------------------------------------------------------------
# Conflict handling
# -----------------------------------------------------------------------------
handle_pywal_conflict() {
    if pacman -Qs python-pywal16 >/dev/null 2>&1; then
        warn "python-pywal16 detected. Removing to avoid conflicts."
        sudo pacman -Rns --noconfirm python-pywal16
    fi
}

# -----------------------------------------------------------------------------
# Config installation
# -----------------------------------------------------------------------------
install_config() {
    log "Installing configuration files."

    if [[ -d "$TARGET_CONFIG_DIR" ]]; then
        log "Existing ~/.config detected. Creating backup at:"
        log "  $BACKUP_DIR"
        cp -a "$TARGET_CONFIG_DIR" "$BACKUP_DIR"
    fi

    log "Syncing dotfiles config/ to ~/.config"
    rsync -av --delete "$SOURCE_CONFIG_DIR/" "$TARGET_CONFIG_DIR/"
}

# -----------------------------------------------------------------------------
# Main execution
# -----------------------------------------------------------------------------
log "Starting Hyprland dotfiles installation."

install_yay
handle_pywal_conflict

log "Installing official packages (pacman)."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

log "Installing AUR/community packages (yay)."
yay -S --needed --noconfirm "${YAY_PKGS[@]}"

install_config

log "Enabling system services."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# -----------------------------------------------------------------------------
# Reboot
# -----------------------------------------------------------------------------
log "Installation completed successfully."
log "System will reboot in 5 seconds."

sleep 5
sudo reboot
