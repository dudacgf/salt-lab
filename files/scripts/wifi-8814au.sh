#!/bin/bash

# instala ferramentas necessárias para o build
sudo apt install -y dkms git build-essential linux-headers-$(uname -r)-amd64 rfkill

# clona git do driver
cd /tmp
git clone https://github.com/morrownr/8814au.git

# instala o git do driver
cd 8814au
sudo bash ./install-driver.sh NoPrompt

# reboot
sudo shutdown -r now
