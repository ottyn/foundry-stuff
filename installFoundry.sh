#!/bin/bash
# chmod a+x /where/i/saved/it/installFoundry.sh
# Foundry Installation on Linux
# 

# update the system and remove older packages
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean

#update the iptables to open ports 80, 443, 30000
sudo iptables -I INPUT 6 -m state --state NEW -p tcp --match multiport --dports 80,443,30000 -j ACCEPT

# save this configuration
sudo netfilter-persistent save

# Add nodejs repository to the system package manager
sudo apt install -y ca-certificates curl gnupg
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

# Add caddy repository to the system package manager
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

# Install nodejs, caddy, unzip, and nano
sudo apt update
sudo apt install nodejs caddy unzip nano -y

# Install pm2
sudo npm install pm2 -g

# Allow pm2 to start and stop after reboot
pm2 startup
sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u $USER --hp $HOME

# make the needed directory
mkdir $HOME/foundry
mkdir $HOME/foundrydata

# Enter Foundry timed url for download
echo "Unzipping foundryvtt.zip"
echo "Please enter the FoundryVTT Timed URL for the NodeJS version:"
read tdurl
wget --output-document $HOME/foundry/foundryvtt.zip "$tdurl"
unzip $HOME/foundry/foundryvtt.zip -d $HOME/foundry/
rm $HOME/foundry/foundryvtt.zip

# Set up pm2 to start foundry vtt at system startup or reboot.
pm2 start "node $HOME/foundry/resources/app/main.js --dataPath=$HOME/foundrydata" --name foundry
pm2 save

# Setting up Caddy reverse proxy
curl -o Caddyfile https://raw.githubusercontent.com/ottyn/foundry-stuff/refs/heads/main/Caddyfile
sudo rm /etc/caddy/Caddyfile
sudo mv Caddyfile /etc/caddy/Caddyfile
echo "Please enter the Domain Name players will use to connect to the server:"
read vtturl
sudo sed -i "s/your.hostname.com/$vtturl/g" /etc/caddy/Caddyfile
sudo service caddy restart

# Edit foundry options.json file to allow connections through proxy and 443
sed -i 's/"proxyPort": null/"proxyPort": 443/g' $HOME/foundrydata/Config/options.json
sed -i 's/"proxySSL": false/"proxySSL": true/g' $HOME/foundrydata/Config/options.json
sed -i 's/"hostname": null/"hostname": "$vtturl"/g' $HOME/foundrydata/Config/options.json

# Create custom assets directories that I use
mkdir $HOME/foundrydata/Data/assets
mkdir $HOME/foundrydata/Data/assets/pc_images
mkdir $HOME/foundrydata/Data/assets/npc_images
mkdir $HOME/foundrydata/Data/assets/maps
mkdir $HOME/foundrydata/Data/assets/token_frames

# Restart Foundry pm2 instance
pm2 restart foundry

# Restarting the system to complete installation
sleep 2
clear
echo "Restarting the system to complete installation"
sleep 3
sudo reboot
