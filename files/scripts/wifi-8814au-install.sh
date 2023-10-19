#!/bin/bash

# install prerequisites
sudo apt install -y linux-headers-$(uname -r) build-essential bc dkms git libelf-dev rfkill iw

# download source
mkdir -p ~/src
cd ~/src
git clone https://github.com/morrownr/8814au.git
cd ~/src/8814au

# install driver
sudo ./install-driver.sh NoPrompt

# reboot
sudo reboot 
