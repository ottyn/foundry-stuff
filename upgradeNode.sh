#!/bin/bash    
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Upgrade NodeJS on Linux

# Check for system updates and clean packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

# Install latest Node Version Manager (NVM) for managing NodeJS versions
# Change installed version as needed per FoundryVTT documentation.
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
nvm install 22
nvm use 22
node -v
npm -v
nvm alias default node
nvm current

# Install latest version of pm2 and update the running process.
npm install pm2@latest -g
pm2 update   # If process hangs at PM2 Updated, hit Ctrl+C to break out.

# Restart any previously running pm2 managed processes.
pm2 save
pm2 resurrect

# This concludes the nodejs update.
