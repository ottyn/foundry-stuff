#!/bin/bash    
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Upgrade NodeJS on Linux

sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

# To update to NodeJS 18, we should stop pm2 processes
pm2 stop all

# Remove the current pm2 from startup to allow for the upgrade.
pm2 unstartup

# Change "node_20.x" in the command below to the new NodeJS version you are wanting to install.
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs
sudo apt update
sudo apt upgrade -y

# Set pm2 to use the upgraded version of NodeJS and set it to run on start again.
npm rebuild -g pm2
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# Restart any previously running pm2 managed processes.
pm2 start all
pm2 save

# This concludes the nodejs update.