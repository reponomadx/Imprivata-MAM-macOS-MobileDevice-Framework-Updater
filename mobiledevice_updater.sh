#!/bin/bash

################################################################################
# Imprivata MAM macOS MobileDevice Framework Updater
#
# Description:
# This script automates the deployment of Apple’s MobileDevice framework package
# to remote macOS endpoints used running Imprivata GroundControl Launchpads.
#
# It performs the following:
# - Validates prerequisites (e.g., sshpass, files)
# - Iterates through a list of devices
# - Uses sshpass + rsync to copy the .pkg
# - Installs the package with sudo
# - Cleans up and restarts GroundControl Launchpad
#
# Prerequisites:
# - Remote Login (SSH) enabled on target Macs
# - A service account with admin privileges
# - Same credentials and folder structure across all target devices
# - sshpass installed on the management Mac
# - This script should be stored securely (recommended: use macOS Keychain to
#   store SSH password instead of hardcoding)
################################################################################

# Path to the .pkg file to be deployed
PKG_PATH="Path/To/MobileDevice.pkg"

# File containing list of target Macs (one per line)
HOSTS_FILE="Path/To/devicelist.txt"

# Directory on the remote machine where the package will be copied
REMOTE_PKG_DIR="Path/To/Downloads"

# SSH credentials (store securely!)
SSH_USER="YOUR_SERVICE_ACCOUNT"
SSH_PASS="YOUR_SERVICE_ACCOUNT_PASSWORD"

# Arrays to track result status per host
SUCCESSFUL_HOSTS=()
FAILED_HOSTS=()
SKIPPED_HOSTS=()

# Validate required files and credentials before proceeding
validate_inputs() {
    if [[ ! -f "$PKG_PATH" ]]; then
        printf "Error: Package file not found: %s\n" "$PKG_PATH" >&2
        return 1
    fi

    if [[ ! -f "$HOSTS_FILE" ]]; then
        printf "Error: Hosts file not found: %s\n" "$HOSTS_FILE" >&2
        return 1
    fi

    if [[ -z "$SSH_PASS" ]]; then
        printf "Error: SSH password is not set\n" >&2
        return 1
    fi

    if ! command -v sshpass >/dev/null 2>&1; then
        printf "Error: sshpass command is required but not installed\n" >&2
        return 1
    fi
}

# Validate hostnames to prevent malformed input
sanitize_host() {
    local host="$1"
    if [[ ! "$host" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        printf "Warning: Invalid hostname skipped: %s\n" "$host" >&2
        return 1
    fi
    return 0
}

# Use rsync over SSH to copy the package to the remote machine
copy_pkg_to_host() {
    local host="$1"

    # Ensure target directory exists
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "mkdir -p '$REMOTE_PKG_DIR'" || {
        printf "Error: Failed to create remote directory on %s\n" "$host" >&2
        return 1
    }

    # Copy package file to the remote Downloads directory
    sshpass -p "$SSH_PASS" rsync -e "ssh -o StrictHostKeyChecking=no" -avz \
        "$PKG_PATH" "$SSH_USER@$host:$REMOTE_PKG_DIR/" || {
        printf "Error: Failed to copy package to %s\n" "$host" >&2
        return 1
    }
}

# Install the .pkg using sudo and perform post-install cleanup
install_pkg_on_host() {
    local host="$1"
    local pkg_file
    pkg_file=$(basename "$PKG_PATH")

    # Perform installation
    sshpass -p "$SSH_PASS" ssh -tt -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "echo \"$SSH_PASS\" | sudo -S installer -pkg '$REMOTE_PKG_DIR/$pkg_file' -target /" || {
        printf "Error: Installation failed on %s\n" "$host" >&2
        return 1
    }

    # Remove the installer file after success
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "rm -f '$REMOTE_PKG_DIR/$pkg_file'" || {
        printf "Warning: Failed to cleanup package on %s\n" "$host" >&2
    }

    # Restart GroundControl Launchpad
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no "$SSH_USER@$host" \
        "pkill 'GroundControl Launchpad'; open /Applications/GroundControl\\ Launchpad.app" || {
        printf "Warning: Failed to restart GroundControl Launchpad on %s\n" "$host" >&2
    }
}

# Iterate through the device list and process each
deploy_to_all_hosts() {
    local host
    exec 3< "$HOSTS_FILE"
    while IFS= read -r -u 3 host || [[ -n "$host" ]]; do
        [[ -z "$host" || "$host" =~ ^# ]] && continue  # Skip blanks/comments
        sanitize_host "$host" || { SKIPPED_HOSTS+=("$host"); continue; }

        printf "\n🚀 Processing host: %s\n" "$host"

        if ! copy_pkg_to_host "$host"; then
            printf "❌ Skipping installation on %s due to copy failure\n" "$host" >&2
            FAILED_HOSTS+=("$host")
            continue
        fi

        if ! install_pkg_on_host "$host"; then
            printf "❌ Installation failed on %s\n" "$host" >&2
            FAILED_HOSTS+=("$host")
            continue
        fi

        printf "✅ Successfully installed package on %s\n" "$host"
        SUCCESSFUL_HOSTS+=("$host")
    done
    exec 3<&-
}

# Script entry point
main() {
    if ! validate_inputs; then
        return 1
    fi

    deploy_to_all_hosts
}

# Run main routine
main

# Display the final deployment summary
echo -e "\n===== 📋 Deployment Summary ====="
echo "✅ Successful installs: ${#SUCCESSFUL_HOSTS[@]}"
for h in "${SUCCESSFUL_HOSTS[@]}"; do echo "   - $h"; done

echo "❌ Failed installs: ${#FAILED_HOSTS[@]}"
for h in "${FAILED_HOSTS[@]}"; do echo "   - $h"; done

echo "⚠️ Skipped hosts: ${#SKIPPED_HOSTS[@]}"
for h in "${SKIPPED_HOSTS[@]}"; do echo "   - $h"; done

echo "=================================="
