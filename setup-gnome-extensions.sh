#!/bin/bash

# GNOME Extensions Setup Script for Rocky Linux
# This script installs extensions and enables only the specified ones

set -e

echo "========================================="
echo "GNOME Extensions Setup Script"
echo "========================================="
echo ""

# Step 1: Install GNOME Tweaks and Extensions App first
echo "Step 0: Upadating & Installing repositories..."
echo "======================================================"
sudo dnf install -y epel-release
sudo dnf config-manager --set-enabled crb
sudo dnf update -y
sudo dnf upgrade -y
echo "Step 1: Installing GNOME Tweaks and Extensions App..."
echo "======================================================"
sudo dnf install -y gnome-tweaks
sudo dnf install -y gnome-extensions-app
echo "GNOME Tweaks and Extensions App installed successfully!"
echo ""

# Check if gnome-shell is installed
if ! command -v gnome-shell &> /dev/null; then
    echo "ERROR: GNOME Shell is not installed!"
    exit 1
fi

# Install Extension Manager (flatpak)
echo ""
echo "Step 2: Installing Extension Manager (GUI)..."
echo "=============================================="
if ! command -v flatpak &> /dev/null; then
    echo "Installing Flatpak..."
    sudo dnf install -y flatpak
fi
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Installing Extension Manager from Flathub..."
echo "IF ERROE APPEARS RESTART MACHINE"
echo "=============================================="
flatpak install -y flathub com.mattjakeman.ExtensionManager

echo ""
echo "Extension Manager installed! You can launch it from your applications menu."
echo ""

# Get GNOME Shell version
GNOME_VERSION=$(gnome-shell --version | cut -d' ' -f3 | cut -d'.' -f1)
echo "Detected GNOME Shell version: $GNOME_VERSION"
echo ""

# Install gnome-extensions-cli if not present (for easier installation)
if ! command -v gext &> /dev/null; then
    echo "Installing gnome-extensions-cli (gext) for easier extension management..."
    pipx install gnome-extensions-cli --system-site-packages 2>/dev/null || pip install --user gnome-extensions-cli
    export PATH="$HOME/.local/bin:$PATH"
fi

# All extensions to install
ALL_EXTENSIONS=(
    "dash-to-panel@jderose9.github.com"
    "user-theme@gnome-shell-extensions.gcampax.github.com"
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
    "gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com"
    "clipboard-history@alexsaveau.dev"
    "logomenu@aryan_k"
    "extension-list@tu.berry"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "Vitals@CoreCoding.com"
    "just-perfection-desktop@just-perfection"
    "dock-from-dash@fthx"
    "search-light@icedman.github.com"
    "CoverflowAltTab@palatis.blogspot.com"
    "ding@rastersoft.com"
    "tiling-assistant@ubuntu.com"
    "ubuntu-appindicators@ubuntu.com"
    "ubuntu-dock@ubuntu.com"
    "apps-menu@gnome-shell-extensions.gcampax.github.com"
    "auto-move-windows@gnome-shell-extensions.gcampax.github.com"
    "drive-menu@gnome-shell-extensions.gcampax.github.com"
    "launch-new-instance@gnome-shell-extensions.gcampax.github.com"
    "light-style@gnome-shell-extensions.gcampax.github.com"
    "native-window-placement@gnome-shell-extensions.gcampax.github.com"
    "screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com"
    "system-monitor@gnome-shell-extensions.gcampax.github.com"
    "window-list@gnome-shell-extensions.gcampax.github.com"
    "windowsNavigator@gnome-shell-extensions.gcampax.github.com"
    "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
)

# Extensions to enable
ENABLE_EXTENSIONS=(
    "dash-to-dock@micxgx.gmail.com"
    "blur-my-shell@aunetx"
    "gnome-fuzzy-app-search@gnome-shell-extensions.Czarlie.gitlab.com"
    "clipboard-history@alexsaveau.dev"
    "logomenu@aryan_k"
    "extension-list@tu.berry"
    "places-menu@gnome-shell-extensions.gcampax.github.com"
    "Vitals@CoreCoding.com"
    "search-light@icedman.github.com"
    "CoverflowAltTab@palatis.blogspot.com"
    "ding@rastersoft.com"
    "tiling-assistant@ubuntu.com"
    "ubuntu-appindicators@ubuntu.com"
    "system-monitor@gnome-shell-extensions.gcampax.github.com"
)

echo "Step 3: Installing all extensions..."
echo "====================================="
for ext in "${ALL_EXTENSIONS[@]}"; do
    echo "Installing: $ext"
    if command -v gext &> /dev/null; then
        gext install "$ext" || echo "  Warning: Could not install $ext (may need manual installation)"
    else
        # Fallback: try to download from extensions.gnome.org manually
        echo "  Note: Please install manually from https://extensions.gnome.org/"
    fi
done

echo ""
echo "Step 4: Disabling all extensions first..."
echo "=========================================="
gnome-extensions list | while read ext; do
    gnome-extensions disable "$ext" 2>/dev/null || true
done

echo ""
echo "Step 5: Enabling selected extensions..."
echo "========================================"
for ext in "${ENABLE_EXTENSIONS[@]}"; do
    echo "Enabling: $ext"
    gnome-extensions enable "$ext" || echo "  Warning: Could not enable $ext"
done

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Enabled extensions:"
gnome-extensions list --enabled
echo ""
echo "Next steps:"
echo "1. Log out and log back in (or restart GNOME Shell with Alt+F2 -> 'r')"
echo "   to ensure all changes take effect."
echo ""
echo "2. You can manage extensions using:"
echo "   - Extension Manager GUI (search 'Extension Manager' in applications)"
echo "   - GNOME Extensions app (search 'Extensions' in applications)"
echo "   - Command line: gnome-extensions list/enable/disable"
echo ""
echo "If some extensions failed to install, you can install them manually:"
echo "   - Open Extension Manager app"
echo "   - Or visit https://extensions.gnome.org/"
