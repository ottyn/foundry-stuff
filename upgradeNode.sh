#!/bin/bash    
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Upgrade NodeJS on Linux

sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

# To upgrade NodeJS, we should stop pm2 processes
pm2 stop all

# Remove the current pm2 from startup to allow for the upgrade.
pm2 unstartup

# Install latest Node Version Manager (NVM) for managing NodeJS versions
# Change installed version as needed per FoundryVTT documentation.
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install 20
node -v
npm -v
nvm alias default node
nvm current

# Set pm2 to use the upgraded version of NodeJS and set it to run on start again.
npm rebuild -g pm2
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# Restart any previously running pm2 managed processes.
pm2 start all
pm2 save

# This concludes the nodejs update.
