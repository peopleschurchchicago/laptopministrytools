#!/bin/bash

# This script is for use in cubic during the priming of custom ISO file for Linux Mint xfce installer.
# This script was developed for the Laptop Ministry at Peoples Church of Chicago in 2024.
# This sciprt is released as Open Source GNU license. This version 1.0 alpha.
# There are absolutley no warranty or liability in the use of this script.


# Exit on errors
set -e

echo "Updating and upgrading packages..."
apt update && apt upgrade -y

echo "Adding repositories for Zoom and Google Chrome..."
# Add Zoom repository
wget -qO - https://zoom.us/linux/download/pubkey | gpg --dearmor -o /usr/share/keyrings/zoom-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/zoom-archive-keyring.gpg] https://zoom.us/linux/debian stable main" | tee /etc/apt/sources.list.d/zoom.list

# Add Google Chrome repository
wget -qO - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list

# Update package list after adding new repositories
apt update

echo "Installing software packages..."
# Install applications
apt install -y \
    zoom \
    google-chrome-stable \
    dragonplayer \
    mpv \
    gthumb \
    krita \
    gtkpod \
    ffmpeg \
    libreoffice \
    audacity \
    losslesscut \
    imagemagick \
    telegram-desktop \
    pithos \
    geany \
    bibletime \
    snapd

# Install snap packages
echo "Installing snap packages..."
snap install webOffice365Desktop

# Install yt-dlp and front-end
echo "Installing yt-dlp with pipx..."
apt install -y pipx
pipx install yt-dlp
# Add an alias for yt-dlp update
echo 'alias yt-dlp-update="pipx upgrade yt-dlp"' >> ~/.bashrc
source ~/.bashrc

# Install ffmpeg front-end (example: Handbrake GUI if available)
apt install -y handbrake

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

echo "Configuring ISO installer to wipe disk before installation..."
cat <<EOF > /usr/local/bin/wipe-and-install.sh
#!/bin/bash
echo "Detecting storage devices..."
lsblk -dp | grep -E 'disk' | awk '{print \$1 " - " \$4}'
echo "Please select the device to wipe (e.g., /dev/sda):"
read -r DEVICE
echo "Wiping selected device \$DEVICE..."
read -p "Are you sure? This will destroy all data on \$DEVICE. (yes/no): " CONFIRM
if [ "\$CONFIRM" == "yes" ]; then
  if [ -d /sys/block/\$(basename \$DEVICE)/queue/rotational ]; then
    ROTATIONAL=\$(cat /sys/block/\$(basename \$DEVICE)/queue/rotational)
    if [ "\$ROTATIONAL" -eq 1 ]; then
      echo "Detected HDD. Performing full dd zero-write wipe..."
      dd if=/dev/zero of=\$DEVICE bs=1M status=progress
    else
      echo "Detected SSD. Performing secure trim wipe..."
      blkdiscard \$DEVICE
    fi
    echo "Wipe complete."
  else
    echo "Unable to determine device type. Skipping wipe."
  fi
else
  echo "Wipe canceled."
fi
echo "Proceeding with installation..."
EOF
chmod +x /usr/local/bin/wipe-and-install.sh

echo "Customization complete. Your ISO is ready for further processing."
