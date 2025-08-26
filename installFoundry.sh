#!/bin/bash
# chmod a+x /where/i/saved/it/installFoundry.sh
# FoundryVTT Installation on Linux
# 

# update the system and remove older packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

# Install base packages to the system package manager
sudo apt install -y ca-certificates curl gnupg wget unzip nano

# Install Node Version Manager (NVM) for managing NodeJS versions
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install 20
node -v
npm -v
nvm alias default node
nvm current

# Install pm2
sudo npm install pm2@latest -g

# Allow pm2 to start and stop after reboot
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# make the needed directory
echo "Folder name for Foundry instance?"
read fvttfolder
echo "Folder name for UserData?"
read fvttuserdata
mkdir $HOME/$fvttfolder
mkdir $HOME/$fvttuserdata

# Enter Foundry timed url for download
echo "Unzipping foundryvtt.zip"
echo "Please enter the FoundryVTT Timed URL for the Linux version:"
read tdurl
wget --output-document $HOME/$fvttfolder/foundryvtt.zip "$tdurl"
unzip $HOME/$fvttfolder/foundryvtt.zip -d $HOME/$fvttfolder/
rm $HOME/$fvttfolder/foundryvtt.zip

# Set up pm2 to start foundry vtt at system startup or reboot.
echo "PM2 instance name?"
read fvttinstance
pm2 start $HOME/$fvttfolder/resources/app/main.js --name $fvttinstance -- --dataPath=$HOME/$fvttuserdata
pm2 save

# Add cloudflare gpg key
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

# Add this repo to your apt repositories
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list

# install cloudflared
sudo apt-get update && sudo apt-get install cloudflared

# Restarting the system to complete installation
sleep 2
clear
echo "Restarting the system to complete installation"
sleep 3
sudo reboot
