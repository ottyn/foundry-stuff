#!/bin/bash
# chmod a+x /where/i/saved/it/backup.sh
# Foundry Backup Script
# Also copies worlds and assets folders to remote server as secondary backup

# Global script variables
# Change to match your environment
#
# SSH private key for remote server
ssh_private_key="$HOME/.ssh/private.key"
# Local FoundryVTT user data path
local_data="$HOME/foundrydata"
# Remote server username and IP address
remote_svr="username@remote IP"
# Path on remote server to Foundry User data folder
remote_path="/home/username/foundrydata"
# Get today's month, day, and year
today=$(date +%Y-%m-%d)
# Get the path to the folder to backup
backup_source="$HOME/foundrydata/"
# Set destination folder for backup
backup_dest="$HOME/backups"
# Create a new backup file
backup_file="$backup_dest/foundrydata_$today.tar.gz"
# Create a log file
log_file="$backup_dest/backup.log"

# Check if the backup directory exists
if [ ! -d "$backup_dest" ]; then
  # Create the backup directory
  mkdir -p "$backup_dest"
fi

# Check if the log file exists
if [ ! -f "$log_file" ]; then
  # Create the log file
  touch "$log_file"
fi

# Add Timestamp
echo "$today" >> $log_file

# Shutting down Foundry instance
echo "Shutting down Foundry server..." >> $log_file
pm2 stop foundry

# Copy world and assets folders to Backup FoundryVTT Server
# This section can be removed if no Backup FoundryVTT Server is used
echo "Copying Worlds folder to Backup Server..." >> $log_file
echo " " >> $log_file
ssh -i $ssh_private_key $remote_svr -- "pm2 stop foundry"
rsync -azh -e "ssh -i $ssh_private_key" --stats $local_data/Data/worlds/ $remote_svr:$remote_path/Data/worlds/ >>
echo " " >> $log_file
echo "Copying Assets folder to Backup Server..." >> $log_file
rsync -azh -e "ssh -i $ssh_private_key" --stats $local_data/Data/assets/ $remote_svr:$remote_path/Data/assets/ >>
echo " " >> $log_file
ssh -i $ssh_private_key $remote_svr -- "pm2 start foundry"

# Backup the folder to the tar.gz file
echo "Creating Foundry Backup..." >> $log_file
echo "    Creating file: $backup_file" >> $log_file
tar -zcf "$backup_file" "$backup_source"

# Remove backups older than 14 days
echo "Cleaning up Backup Files..." >> $log_file
find $backup_dest -name '*.tar.gz' -type f -mtime +15 -exec rm -f {} \; -exec echo "    Deleting file" {} >> $log_file \;

# Restarting Foundry instance
echo "Starting Foundry server..." >> $log_file
pm2 start foundry
echo " " >> $log_file
