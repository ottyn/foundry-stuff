#!/bin/bash
# chmod a+x /where/i/saved/it/upgradeNode.sh
# Install/Upgrade NVM, NodeJS, NPM, and PM2 on Linux
set -Eeuo pipefail
trap 'echo "Error on line $LINENO. Exiting."; exit 1' ERR

# Configurable Node version
NODE_VERSION="22"

### FUNCTIONS ###

update_system() {
  echo "Updating system packages..."
  sudo apt update && sudo apt upgrade -y
  sudo apt autoremove -y && sudo apt autoclean
}

backup_pm2() {
  if command -v pm2 &> /dev/null && pm2 list &> /dev/null; then
    echo "Backing up existing PM2 process list..."
    pm2 save

    # Create a timestamped backup of the dump file
    if [[ -f "$HOME/.pm2/dump.pm2" ]]; then
      cp "$HOME/.pm2/dump.pm2" "$HOME/.pm2/dump.pm2.backup.$(date +%Y%m%d_%H%M%S)"
      echo "Created backup: $HOME/.pm2/dump.pm2.backup.$(date +%Y%m%d_%H%M%S)"
    fi

    echo "Stopping PM2 daemon..."
    pm2 kill
  else
    echo "No existing PM2 processes found."
  fi

  # Ensure the dump file exists for later restoration
  if [[ -f "$HOME/.pm2/dump.pm2" ]]; then
    echo "PM2 dump file preserved at $HOME/.pm2/dump.pm2"
  fi
}

cleanup_old_nvm() {
  local SHELL_RC=""

  if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
  fi

  if [[ -n "$SHELL_RC" ]] && grep -q 'NVM_DIR' "$SHELL_RC"; then
    echo "Removing old NVM configuration from $SHELL_RC..."
    cp "$SHELL_RC" "${SHELL_RC}.backup.$(date +%Y%m%d_%H%M%S)"

    # Remove NVM lines
    grep -v 'NVM_DIR\|nvm\.sh\|bash_completion.*nvm\|# NVM' "$SHELL_RC" > "${SHELL_RC}.tmp"
    mv "${SHELL_RC}.tmp" "$SHELL_RC"
  fi
}

install_nvm_node() {
  # Clean up old NVM directory
  if [[ -d "$HOME/.nvm" ]]; then
    echo "Existing NVM installation found at $HOME/.nvm - removing it..."
    rm -rf "$HOME/.nvm"
  fi

  # Clean up old NVM references in shell config BEFORE installing
  cleanup_old_nvm

  echo "Installing NVM..."
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash

  # Now source the FRESH NVM that was just installed
  export NVM_DIR="$HOME/.nvm"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

  echo "Installing Node.js v$NODE_VERSION..."
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION"
  nvm use "$NODE_VERSION"

  # Reinstall global packages from previous version if upgrading
  if nvm ls | grep -q "v[0-9]"; then
    echo "Reinstalling global packages from previous Node version..."
    nvm reinstall-packages default || true
  fi

  echo "Using Node version: $(node -v)"
  echo "Using NPM version: $(npm -v)"
}

install_pm2() {
  # Force remove old PM2 startup configuration
  if command -v pm2 &> /dev/null; then
    echo "Removing old PM2 startup configuration..."
    pm2 unstartup systemd -u "$USER" --hp "$HOME" 2>/dev/null || true
    sudo systemctl disable pm2-$(whoami) 2>/dev/null || true
    sudo rm -f /etc/systemd/system/pm2-$(whoami).service 2>/dev/null || true
    sudo systemctl daemon-reload
  fi

  echo "Installing PM2 for Node $(node -v)..."
  npm install pm2@latest -g

  # Verify PM2 is accessible
  if ! command -v pm2 &> /dev/null; then
    echo "PM2 installation failed"
    exit 1
  fi

  echo "Configuring PM2 startup..."

  # Capture the startup command from pm2's output (allow grep to fail)
  STARTUP_CMD=$(pm2 startup 2>&1 | grep "sudo env" | tail -n 1 || true)

  if [ -n "$STARTUP_CMD" ]; then
    echo "Executing: $STARTUP_CMD"
    eval "$STARTUP_CMD"
  else
    echo "Warning: Could not parse PM2 startup command"
    echo "PM2 startup output:"
    pm2 startup
    echo ""
    echo "You may need to run the startup command manually"
  fi

  pm2 save --force
  pm2 update
}

restore_pm2() {
  if [[ -f "$HOME/.pm2/dump.pm2" ]]; then
    echo "Restoring PM2 processes..."
    pm2 resurrect
    # Verify processes were restored
    echo ""
    echo "Current PM2 processes:"
    pm2 list

    # Save the configuration with the new PM2/Node setup
    pm2 save --force

    echo "PM2 processes restored and saved"
  else
    echo "No PM2 dump file found to restore."
  fi
}

add_nvm_to_shell() {
  # This function now just verifies NVM was added by the installer
  local SHELL_RC=""

  if [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
  elif [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
  fi

  if [[ -n "$SHELL_RC" ]]; then
    # NVM install script should have already added this, but verify
    if ! grep -q 'NVM_DIR' "$SHELL_RC"; then
      echo "Adding NVM to $SHELL_RC..."
      cat >> "$SHELL_RC" << 'EOF'

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
    else
      echo "NVM already configured in $SHELL_RC"
    fi

    # Source the shell config to make NVM available immediately
    echo "Reloading shell configuration..."
    # shellcheck disable=SC1090
    source "$SHELL_RC"
  fi
}

### MAIN EXECUTION ###

update_system
backup_pm2
install_nvm_node
install_pm2
restore_pm2
add_nvm_to_shell

echo -e "\nUpgrade complete!"
echo "NVM:  $(nvm --version)"
echo "Node: $(node -v)"
echo "NPM:  $(npm -v)"
echo "PM2:  $(pm2 -v)"
echo ""
echo "Note: NVM, Node, and PM2 are now available in this session and will persist in new shells"
