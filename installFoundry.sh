#!/bin/bash
# chmod a+x /where/i/saved/it/installFoundry.sh
# Automated FoundryVTT Installation on Linux (multi-instance support with auto-ports + reinstall option)

set -Eeuo pipefail
trap 'echo "❌ Error on line $LINENO. Exiting."; exit 1' ERR

### FUNCTIONS ###

update_system() {
  echo "🔄 Updating system packages..."
  sudo apt update && sudo apt upgrade -y
  sudo apt autoremove -y && sudo apt autoclean
}

install_dependencies() {
  echo "📦 Installing required packages..."
  sudo apt install -y ca-certificates curl gnupg wget unzip nano
}

install_nvm_node() {
  if [[ -d "$HOME/.nvm" ]]; then
    echo "⚠️ Existing NVM installation found at $HOME/.nvm — removing it..."
    rm -rf "$HOME/.nvm"
  fi

  echo "⬇️ Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    source "$NVM_DIR/nvm.sh"
  fi
  if [[ -s "$NVM_DIR/bash_completion" ]]; then
    source "$NVM_DIR/bash_completion"
  fi

  echo "⬇️ Installing Node.js v$NODE_VERSION..."
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use "$NODE_VERSION"

  echo "✅ Using Node version: $(node -v)"
  echo "✅ Using NPM version: $(npm -v)"
}

install_pm2() {
  if ! command -v pm2 &> /dev/null; then
    echo "⬇️ Installing PM2..."
  else
    echo "🔄 Updating PM2..."
  fi

  npm install pm2@latest -g
  pm2 update

  echo "⚙️ Configuring PM2 startup..."
  sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u "$USER" --hp "$HOME"

  if [[ -f "$HOME/.pm2/dump.pm2" ]]; then
    echo "♻️ Restoring previous PM2 processes..."
    pm2 resurrect
  else
    echo "ℹ️ No PM2 dump file found, skipping resurrect."
  fi
}

create_directories() {
  read -rp "📁 Enter folder name for Foundry server install: " fvttfolder
  [[ -z "$fvttfolder" ]] && { echo "❌ Folder names cannot be empty"; exit 1; }

  mkdir -p "$HOME/$fvttfolder"
  mkdir -p "$HOME/$fvttfolder/FoundryVTT"
  mkdir -p "$HOME/$fvttfolder/FoundryUserData"

  export FVTT_FOLDER="$HOME/$fvttfolder/FoundryVTT"
  export FVTT_USERDATA="$HOME/$fvttfolder/FoundryUserData"
}

download_foundry() {
  read -rp "🌐 Enter FoundryVTT Timed URL for the NodeJS version: " tdurl
  [[ -z "$tdurl" ]] && { echo "❌ URL cannot be empty"; exit 1; }

  echo "⬇️ Downloading FoundryVTT..."
  wget -O "$FVTT_FOLDER/foundryvtt.zip" "$tdurl"

  echo "📂 Extracting..."
  unzip -q "$FVTT_FOLDER/foundryvtt.zip" -d "$FVTT_FOLDER/"
  rm -f "$FVTT_FOLDER/foundryvtt.zip"
}

get_next_port() {
  local base_port=30000
  local used_ports
  used_ports=$(pm2 jlist | grep -o '"--port=[0-9]\+"' | grep -o '[0-9]\+' || true)

  local port=$base_port
  while echo "$used_ports" | grep -q "$port"; do
    port=$((port+1))
  done

  echo "$port"
}

configure_pm2() {
  read -rp "🔧 Enter PM2 instance name: " fvttinstance
  [[ -z "$fvttinstance" ]] && { echo "❌ PM2 instance name cannot be empty"; exit 1; }

  local port
  port=$(get_next_port)

  echo "🚀 Starting FoundryVTT instance '$fvttinstance' on port $port"

  pm2 start "$FVTT_FOLDER/main.js" \
    --name "$fvttinstance" -- --dataPath="$FVTT_USERDATA" --port="$port"

  pm2 save
}

install_cloudflared() {
  if command -v cloudflared >/dev/null 2>&1; then
    echo "✅ Cloudflared is already installed. Skipping installation."
    return
  fi

  echo "☁️ Installing Cloudflared..."
  sudo mkdir -p --mode=0755 /usr/share/keyrings
  curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | \
    sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
  echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | \
    sudo tee /etc/apt/sources.list.d/cloudflared.list
  sudo apt update && sudo apt install -y cloudflared
}

restart_system() {
  echo "🔄 Installation complete. Restarting in 5 seconds..."
  sleep 5
  sudo reboot
}

install_instance() {
  create_directories
  download_foundry
  configure_pm2
}

prompt_additional_instances() {
  while true; do
    read -rp "➕ Do you want to install another Foundry instance? (y/n): " choice
    case "$choice" in
      y|Y ) install_instance ;;
      n|N ) break ;;
      * ) echo "❌ Please enter y or n." ;;
    esac
  done
}

reinstall_instance() {
  echo "📋 Available PM2 instances:"
  mapfile -t instances < <(pm2 jlist | jq -r '.[].name')

  if [[ ${#instances[@]} -eq 0 ]]; then
    echo "❌ No PM2 instances found."
    exit 1
  fi

  for i in "${!instances[@]}"; do
    echo "$((i+1))) ${instances[$i]}"
  done

  read -rp "Select an instance [1-${#instances[@]}]: " choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#instances[@]} )); then
    echo "❌ Invalid choice."
    exit 1
  fi

  instance_name="${instances[$((choice-1))]}"
  echo "✅ Selected instance: $instance_name"

  # Use pm2 jlist JSON output for reliable parsing
  instance_json=$(pm2 jlist | jq -r --arg NAME "$instance_name" '.[] | select(.name==$NAME)')

  # Extract the script path and dataPath from JSON
  script_path=$(echo "$instance_json" | jq -r '.pm2_env.pm_exec_path')
  FVTT_USERDATA=$(echo "$instance_json" | jq -r '.pm2_env.args[]' | grep -- '--dataPath=' | cut -d'=' -f2)

  # Determine FVTT_FOLDER from script_path
  FVTT_FOLDER="${script_path%/main.js}"

  if [[ -z "$FVTT_FOLDER" || -z "$FVTT_USERDATA" ]]; then
    echo "❌ Could not determine FoundryVTT paths for $instance_name"
    exit 1
  fi

  echo "📂 Found install path: $FVTT_FOLDER"
  echo "📂 Found user data path: $FVTT_USERDATA"

  pm2 stop "$instance_name"

  read -rp "🌐 Enter FoundryVTT Timed URL for the NodeJS version: " tdurl
  [[ -z "$tdurl" ]] && { echo "❌ URL cannot be empty"; exit 1; }

  mv "$FVTT_FOLDER" "${FVTT_FOLDER}_backup_$(date +%s)"
  mkdir -p "$FVTT_FOLDER"

  echo "⬇️ Downloading FoundryVTT..."
  wget -O "$FVTT_FOLDER/foundryvtt.zip" "$tdurl"
  unzip -q "$FVTT_FOLDER/foundryvtt.zip" -d "$FVTT_FOLDER/"
  rm -f "$FVTT_FOLDER/foundryvtt.zip"

  pm2 start "$instance_name"
  pm2 save

  echo "✅ Reinstall of $instance_name completed successfully."
}

### MAIN EXECUTION ###
echo "====================================="
echo "   FoundryVTT Multi-Instance Installer"
echo "====================================="

echo "1) New Install"
echo "2) Additional Instance"
echo "3) Reinstall Existing Instance"
read -rp "Choose an option [1-3]: " choice

case "$choice" in
  1 )
    update_system
    install_dependencies
    install_nvm_node
    install_pm2
    install_instance
    prompt_additional_instances

    read -rp "☁️ Do you want to install Cloudflared (y/n)? " cf_choice
    if [[ "$cf_choice" =~ ^[Yy]$ ]]; then
      install_cloudflared
    fi

    read -rp "🔄 Do you want to reboot the system now (recommended)? (y/n): " reboot_choice
    if [[ "$reboot_choice" =~ ^[Yy]$ ]]; then
      restart_system
    else
      echo "⚠️ Skipping reboot. Please reboot manually later."
    fi
    ;;
  2 )
    install_instance
    prompt_additional_instances
    ;;
  3 )
    reinstall_instance
    ;;
  * )
    echo "❌ Invalid choice. Exiting."
    exit 1
    ;;
esac
