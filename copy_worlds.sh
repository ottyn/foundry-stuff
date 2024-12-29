#!/bin/bash
# chmod a+x /where/i/saved/it/copy_worlds.sh
# Copy FoundryVTT worlds and assets folders to remote backup server
# 

# Global script variables
# Replace <...> to match your environment
#
# SSH private key for remote server
$ssh_private_key="$HOME/.ssh/<private.key>"
# Local FoundryVTT user data path
$local_data="$HOME/foundrydata"
# Remote server username and IP address
$remote_svr="<username>@<remote IP>"
# Remote server FoundryVTT user data path
$remote_path="<full path to folder containing Data dir>"

pm2 stop foundry

ssh -i $ssh_private_key $remote_svr -- "pm2 stop foundry"

rsync -azh -e "ssh -i $ssh_private_key" --stats $local_data/Data/worlds/ $remote_svr:$remote_path/Data/worlds/
rsync -azh -e "ssh -i $ssh_private_key" --stats $local_data/Data/assets/ $remote_svr:$remote_path/Data/assets/

ssh -i $ssh_private_key $remote_svr -- "pm2 start foundry"

pm2 start foundry
