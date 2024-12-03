#!/bin/bash

# This script is for use in cubic during the priming of custom ISO file for Linux Mint xfce installer and includes a menu entry to a BASH script generated for updating Zoom and Google Chrome.
# This script was developed for the Laptop Ministry at Peoples Church of Chicago in 2024.
# This sciprt is released as Open Source GNU license. This version 1.4 alpha.
# There are absolutley no warranty or liability in the use of this script.

# Exit on errors
set -e

echo "Updating and upgrading packages..."
apt update && apt upgrade -y

echo "Adding repositories for Google Chrome..."
# Add Google Chrome repository
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# Enable snap support for Linux Mint
echo "Enabling snap support on Linux Mint..."
if [ -f /etc/apt/preferences.d/nosnap.pref ]; then
    sudo rm /etc/apt/preferences.d/nosnap.pref
fi
apt update
apt install -y snapd

# Update package list after adding new repositories
apt update

echo "Installing software packages..."
# Install applications, skipping unavailable packages
apt install -y \
    google-chrome-stable \
    dragonplayer \
    mpv \
    gthumb \
    krita \
    ffmpeg \
    libreoffice \
    audacity \
    imagemagick \
    pithos \
    geany \
    bibletime || true

echo "Handling additional software installations..."
# Install Telegram Desktop via PPA or direct download
add-apt-repository -y ppa:atareao/telegram
apt update && apt install -y telegram-desktop || echo "Telegram Desktop could not be installed."

# Install LosslessCut via Snap
snap install losslesscut || echo "LosslessCut installation failed via Snap."

# Download and install Zoom
echo "Installing Zoom by downloading the latest package..."
wget -O /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
dpkg -i /tmp/zoom.deb || apt-get -f install -y
rm /tmp/zoom.deb

# Install snap packages
echo "Installing snap packages..."
snap install webOffice365Desktop || echo "Snap installation failed."

# Install yt-dlp and front-end
echo "Installing yt-dlp with pipx..."
apt install -y pipx
pipx install yt-dlp
# Add an alias for yt-dlp update
echo 'alias yt-dlp-update="pipx upgrade yt-dlp"' >> ~/.bashrc
source ~/.bashrc

# Install ffmpeg front-end (example: Handbrake GUI if available)
apt install -y handbrake || echo "Handbrake installation failed."

echo "Setting up timezone to Chicago / Central Time..."
ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime

echo "Configuring default user and password..."
# Set default user and password
echo "home:password" | chpasswd
cat <<EOF > /etc/default/useradd
GROUP=users
HOME=/home
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
EOF
echo "Prompting user to change password at first login..."
passwd -e home

# Create update script
echo "Creating update script for Zoom and Google Chrome..."
cat <<EOF > /usr/local/bin/update-software.sh
#!/bin/bash
# Update system and Google Chrome
echo "Updating system and Google Chrome..."
sudo apt update && sudo apt upgrade -y

# Download the latest Zoom package
echo "Downloading the latest Zoom package..."
wget -O /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb

# Install Zoom package
echo "Installing the latest Zoom version..."
sudo dpkg -i /tmp/zoom.deb || sudo apt-get -f install -y

# Clean up
rm /tmp/zoom.deb

echo "All updates are complete."
EOF
chmod +x /usr/local/bin/update-software.sh

# Create a desktop menu icon for the update script
echo "Creating desktop menu entry for Update Zoom Etc..."
cat <<EOF > /usr/share/applications/update-zoom-etc.desktop
[Desktop Entry]
Name=Update Zoom Etc
Comment=Update Zoom and Google Chrome to the latest versions
Exec=sudo /usr/local/bin/update-software.sh
Icon=system-software-update
Terminal=true
Type=Application
Categories=System;Utility;
EOF

echo "Customization complete. Your ISO is ready for further processing."
