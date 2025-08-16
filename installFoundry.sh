#!/bin/bash
# chmod a+x /where/i/saved/it/installFoundry.sh
# FoundryVTT Installation on Linux
# 

# update the system and remove older packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

# Install base packages to the system package manager
sudo apt install -y ca-certificates curl gnupg wget unzip nano

# Install Node Version Manager (NVM) for managing NodeJS versions
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
nvm install 20
node -v
nvm current
npm -v
nvm alias default node

# Install pm2
sudo npm install pm2 -g

# Allow pm2 to start and stop after reboot
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# make the needed directory
echo "Folder name for Foundry?"
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
echo "Foundry instance name?"
read fvttinstance
pm2 start $HOME/$fvttfolder/resources/app/main.js --name $fvttinstance -- --dataPath=$HOME/$fvttuserdata
pm2 save

# Restarting the system to complete installation
sleep 2
clear
echo "Restarting the system to complete installation"
sleep 3
sudo reboot
