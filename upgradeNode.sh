#!/bin/bash
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Install/Upgrade NVM, NodeJS, NPM, and PM2 on Linux

set -Eeuo pipefail
trap 'echo "❌ Error on line $LINENO. Exiting."; exit 1' ERR

# Configurable Node version
NODE_VERSION="22"

### FUNCTIONS ###

update_system() {
  echo "🔄 Updating system packages..."
  sudo apt update && sudo apt upgrade -y
  sudo apt autoremove -y && sudo apt autoclean
}

backup_pm2() {
  if command -v pm2 &> /dev/null && pm2 list &> /dev/null; then
    echo "💾 Backing up existing PM2 process list..."
    pm2 save
    pm2 kill
  else
    echo "ℹ️ No existing PM2 processes found."
  fi
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

### MAIN EXECUTION ###
update_system
backup_pm2
install_nvm_node
install_pm2

echo -e "\n✅ Upgrade complete!"
echo "NVM:  $(nvm --version)"
echo "Node: $(node -v)"
echo "NPM:  $(npm -v)"
echo "PM2:  $(pm2 -v)"
