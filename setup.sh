#!/bin/bash

set -e

echo "🚀 Instalador de dependencias para Hyprland (Arch Linux)"

# -----------------------------
# Verificar yay
# -----------------------------
if ! command -v yay &> /dev/null; then
    echo "🔧 yay no está instalado. Instalándolo..."
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "✅ yay ya está instalado"
fi

# -----------------------------
# Paquetes oficiales (pacman)
# -----------------------------
PACMAN_PKGS=(
    bluez
    blueman
    networkmanager
    gvfs
    libnotify
)

echo "📦 Instalando paquetes oficiales..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"

# -----------------------------
# Paquetes AUR / community (yay)
# -----------------------------
YAY_PKGS=(
    hyprland
    waybar
    hyprpicker
    pywal
    swaync
    wofi
    neovim
    wlogout
    starship
)

echo "📦 Instalando paquetes AUR / community..."
yay -S --needed --noconfirm "${YAY_PKGS[@]}"

# -----------------------------
# Habilitar servicios necesarios
# -----------------------------
echo "⚙️ Habilitando servicios..."
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

echo "✅ Instalación completada con éxito"
echo "✨ Reinicia tu sesión o el sistema para aplicar todos los cambios"

