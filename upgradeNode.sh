#!/bin/bash
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Upgrade NodeJS & PM2 safely with NVM for FoundryVTT

set -Eeuo pipefail

# === System update (optional if you want to keep OS updated here) ===
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y

# === Ensure NVM is installed ===
export NVM_DIR="$HOME/.nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
fi

# Load NVM into this shell session
# (otherwise "nvm: command not found")
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck disable=SC1090
    source "$NVM_DIR/nvm.sh"
else
    echo "❌ NVM not found after installation"
    exit 1
fi

# === Install and use desired Node.js version ===
NODE_VERSION=22
nvm install "$NODE_VERSION"
nvm use "$NODE_VERSION"
nvm alias default "$NODE_VERSION"

echo "✅ Using Node version: $(node -v)"
echo "✅ Using NPM version: $(npm -v)"

# === Install or update PM2 ===
npm install -g pm2@latest

# === Restart PM2 processes ===
pm2 update || true   # continue even if update hangs
pm2 save
pm2 resurrect

echo "🎉 NodeJS + PM2 upgrade complete!"
