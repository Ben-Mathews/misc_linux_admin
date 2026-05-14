#!/usr/bin/env bash
#
# Ubuntu Desktop Setup Script
#
# Installs common desktop packages, virtualization tools, GNOME extensions,
# Chrome, VS Code, Obsidian, SABnzbd, Plex, and VM guest tools.
#
# Usage:
#   ./setup.sh [--force-all] [--help]
#
# Options:
#   --force-all    Run non-VM-only sections even when inside a VM.
#   -h, --help     Show this help message and exit.
#
# Notes:
#   Do not run this script with sudo. It will call sudo internally as needed.
#

set -euo pipefail

force_all=false

show_help() {
    cat <<EOF
Ubuntu Desktop Setup Script

Installs common desktop packages, virtualization tools, GNOME extensions,
Chrome, VS Code, Obsidian, SABnzbd, Plex, and VM guest tools.

Usage:
  $(basename "$0") [OPTIONS]

Options:
  --force-all
      Run non-VM-only sections even when this script detects it is running
      inside a VM. Without this option, SABnzbd, VS Code, Obsidian, Plex,
      and the virt-viewer wrapper are skipped inside VMs.

  -h, --help
      Show this help message and exit.

Important:
  Do not run this script with sudo. The script calls sudo internally when needed.

Examples:
  ./$(basename "$0")
  ./$(basename "$0") --force-all
  ./$(basename "$0") --help
EOF
}

for arg in "$@"; do
    case "$arg" in
        --force-all)
            force_all=true
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Error: unknown option: $arg" >&2
            echo "Run '$0 --help' for usage." >&2
            exit 1
            ;;
    esac
done

if [[ "$EUID" -eq 0 || -n "${SUDO_USER:-}" ]]; then
    echo "Error: do not run this script as root or with sudo." >&2
    exit 1
fi

#
# Install main packages
#
sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt-get install -y gnome-browser-connector vim build-essential make git gettext htop alacarte vlc
sudo snap refresh

#
# Install dash to panel
#
pushd /tmp
rm -rf ./dash-to-panel
git clone https://github.com/home-sweet-gnome/dash-to-panel.git
cd dash-to-panel/
make install
popd

#
# Chrome
#
pushd /tmp
wget -O google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb
popd
sudo apt-get install -y chrome-gnome-shell  # For gnome extensions support

#
# On VM's
#
if systemd-detect-virt --quiet --vm; then
    sudo apt install -y spice-vdagent qemu-guest-agent
    sudo systemctl enable qemu-guest-agent
    sudo systemctl start qemu-guest-agent
    sudo sed -i 's/^X-GNOME-Autostart-Phase=/#X-GNOME-Autostart-Phase=/' /etc/xdg/autostart/spice-vdagent.desktop
    sudo systemctl status qemu-guest-agent
    # Reboot for this tot take effect
fi

if ! systemd-detect-virt --quiet --vm || [[ "$force_all" == true ]]; then
    #
    # Install all packages (redundant with previous command)
    #
    sudo apt-get install -y qemu-system libvirt-daemon-system virt-manager virt-viewer libguestfs-tools gnome-browser-connector samba smbclient vim openssh-server python3-dev python3-venv python3-pip build-essential make git gettext tmux net-tools htop alacarte curl jq gimp inkscape vlc calibre filezilla 

    #
    # Install Sabnzbplus
    #
    sudo add-apt-repository -y ppa:jcfp/nobetas
    sudo apt-get update 
    sudo apt-get install -y sabnzbdplus
    
    #
    # VS code
    #
    pushd /tmp && wget -O code_latest_amd64.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" && sudo apt install -y ./code_latest_amd64.deb && popd

    #
    # Obsidian
    #
    pushd /tmp && url="$(wget -qO- https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest | grep -oP 'https://[^"]+amd64\.deb')" && wget -O obsidian_latest_amd64.deb "$url" && sudo apt install -y ./obsidian_latest_amd64.deb && popd

    #
    # Plex
    #
    sudo snap install plexmediaserver
    sudo systemctl enable snap.plexmediaserver.plexmediaserver.service
    sudo systemctl start snap.plexmediaserver.plexmediaserver.service
    
    #
    # Some other fixes
    #
    mkdir -p ~/.local/bin && printf '%s\n' '#!/usr/bin/env bash' 'exec /usr/bin/virt-viewer --zoom=200 --auto-resize=never "$@"' > ~/.local/bin/virt-viewer && chmod +x ~/.local/bin/virt-viewer
fi

#
# Fix bold fonts in taskbar for dash-to-panel
#
css="$HOME/.local/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com/stylesheet.css"; grep -q "font-weight: normal" "$css" || cat <<'EOF' >> "$css"

#panel,
#panel *,
.panel-button,
.panel-button *,
.dash-label,
.window-title {
    font-weight: normal !important;
}
EOF
gnome-extensions disable dash-to-panel@jderose9.github.com && gnome-extensions enable dash-to-panel@jderose9.github.com
cat > ~/enable_dash_to_panel.sh <<'EOF'
#!/bin/bash
gnome-extensions disable dash-to-panel@jderose9.github.com && gnome-extensions enable dash-to-panel@jderose9.github.com
dconf write /org/gnome/shell/extensions/dash-to-panel/panel-sizes "'{\"RHT-0x00000000\":32}'"
dconf write /org/gnome/shell/extensions/dash-to-panel/group-apps false
dconf write /org/gnome/shell/extensions/dash-to-panel/isolate-workspaces true
dconf write /org/gnome/shell/extensions/dash-to-panel/isolate-monitors true
gnome-extensions disable dash-to-panel@jderose9.github.com && gnome-extensions enable dash-to-panel@jderose9.github.com
rm -f ~/enable_dash_to_panel.sh
EOF
chmod u+x ~/enable_dash_to_panel.sh
echo -e "#\n#\n#\nLog out, log back in, and run run ~/enable_dash_to_panel.sh to enable and configure Dash-to-Panel\n#\n#\n#\n"

