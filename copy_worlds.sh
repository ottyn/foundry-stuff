#!/bin/bash
# chmod a+x /where/i/saved/it/copy_worlds.sh
# Copy FoundryVTT worlds and assets folders to remote backup server
# ssh -i /home/ubuntu/.ssh/contabo_pri.key cbuckbee@85.239.241.151

# Global script variables
# Change to match your environment
#
# SSH private key for remote server
ssh_private_key="$HOME/.ssh/key_filename"
# Local FoundryVTT user data path
local_data="$HOME/path_to/FoundryUserData"
# Remote server username and IP address
remote_svr="username@IP"
# Remote server FoundryVTT user data path
remote_path="/full_path_to/FoundryUserData"

echo Stopping PF2e Foundry Instances...
pm2 stop pf2e
ssh -i $ssh_private_key $remote_svr -- "pm2 stop pf2e"

echo Copying Worlds to Backup Foundry Server...
scp -r -q -o LogLevel=QUIET -i $ssh_private_key $local_data/Data/worlds/ $remote_svr:$remote_path/Data/
echo Copying Assets to Backup Foundry Server...
scp -r -q -o LogLevel=QUIET -i $ssh_private_key $local_data/Data/assets/ $remote_svr:$remote_path/Data/
echo Copying BBMM-Data to Backup Foundry Server...
scp -r -q -o LogLevel=QUIET -i $ssh_private_key $local_data/Data/bbmm-data/ $remote_svr:$remote_path/Data/

echo Restarting PF2e Foundry Instances...
ssh -i $ssh_private_key $remote_svr -- "pm2 start pf2e"
pm2 start pf2e
