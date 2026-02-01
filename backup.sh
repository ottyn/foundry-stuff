#!/bin/bash
#
# FoundryVTT Backup Script
# Based on using installFoundry.sh script in this repo
# Creates a local compressed backup and syncs Worlds/Assets to remote server
# Remove/comment Remote Stop, Sync, and Start sections if not copying Worlds/Assets to remote server

set -Eeuo pipefail
trap 'echo "[$(date +%F %T)] Error on line $LINENO. Exit code $?" | tee -a "$log_file"' ERR

# ─────────────────────────────
# Configurable Variables
# Edit variables with <> notation to to match your environment
# ─────────────────────────────
ssh_private_key="$HOME/.ssh/key_filename"           # SSH private key
local_path="$HOME/pf2e"                                # Local server path that contains the FoundryVTT and FoundryUserData folders
local_instance="pf2e"                                  # Local PM2 Instance name for Foundry
remote_svr="username@IP"                   # Remote server
remote_path="/path_to/FoundryUserData"      # Remote FoundryUserData folder path
remote_instance="pf2e"                                 # Remote server PM2 Instance name for Foundry
today=$(date +%Y-%m-%d)                                # Backup date
backup_dest="$HOME/backup"                             # Local backup folder
backup_file="$backup_dest/foundrydata_$today.tar.gz"   # Backup archive name
log_file="$backup_dest/backup.log"                     # Log file

# ─────────────────────────────
# Logging Function
# ─────────────────────────────
log() { echo "[$(date +%Y-%m-%d)] $*" | tee -a "$log_file"; }

# ─────────────────────────────
# Prep Work
# ─────────────────────────────
if [ ! -d "$backup_dest" ]; then
    mkdir -p "$backup_dest"
    touch "$log_file"
    log "Created backup directory and log file at $backup_dest"
elif [ ! -f "$log_file" ]; then
    touch "$log_file"
    log "Created missing log file $log_file"
else
    log "Backup destination and log file already exist, continuing..."
fi

# Locking to prevent overlap
lockfile="$backup_dest/.backup.lock"
exec 9>"$lockfile"
if ! flock -n 9; then
    log "Backup already running. Exiting."
    exit 1
fi

# ─────────────────────────────
# Local Foundry Stop
# ─────────────────────────────
log "Stopping local Foundry..."
pm2 stop $local_instance || { log "Failed to stop local Foundry"; exit 1; }

# ─────────────────────────────
# Remote Stop
# ─────────────────────────────
log "Stopping remote Foundry..."
ssh -i "$ssh_private_key" "$remote_svr" "pm2 stop $remote_instance" \
    || { log "Failed to stop remote Foundry"; exit 1; }

# ─────────────────────────────
# Remote Sync
# ─────────────────────────────
log "Syncing Worlds to remote..."
scp -r -q -o LogLevel=QUIET -i $ssh_private_key \
        "$local_path/FoundryUserData/Data/worlds/" "$remote_svr:$remote_path/Data/" \
        || { log "Worlds sync failed"; exit 1; }

log "Syncing Assets to remote..."
scp -r -q -o LogLevel=QUIET -i $ssh_private_key \
        "$local_path/FoundryUserData/Data/assets/" "$remote_svr:$remote_path/Data/" \
        || { log "Assets sync failed"; exit 1; }

log "Syncing BBMM-Data to remote..."
scp -r -q -o LogLevel=QUIET -i $ssh_private_key \
        "$local_path/FoundryUserData/Data/bbmm-data/" "$remote_svr:$remote_path/Data/" \
        || { log "BBMM-Data sync failed"; exit 1; }

# ─────────────────────────────
# Remote Start
# ─────────────────────────────
log "Starting remote Foundry..."
ssh -i "$ssh_private_key" "$remote_svr" "pm2 restart $remote_instance || pm2 start $remote_instance" \
    || { log "Failed to start remote Foundry"; exit 1; }

# ─────────────────────────────
# Local Backup Archive
# ─────────────────────────────
log "Creating backup archive $backup_file"
tar -zcf "$backup_file" -C "$local_path" "FoundryUserData" \
    || { log "Failed to create local archive"; exit 1; }

# ─────────────────────────────
# Cleanup Old Backups
# ─────────────────────────────
log "Cleaning up backups older than 15 days..."
find "$backup_dest" -name 'foundrydata_*.tar.gz' -type f -mtime +15 -print -delete \
    >> "$log_file" 2>&1

# ─────────────────────────────
# Restart Local Foundry
# ─────────────────────────────
log "Starting local Foundry..."
pm2 restart $local_instance || pm2 start $local_instance || { log "Failed to start local Foundry"; exit 1; }

log "Backup completed successfully"
