#!/bin/bash

# Vintage Story Server Update Script
# Usage: sudo ./update_vs_server.sh [version]
# Example: sudo ./update_vs_server.sh 1.20.11

# Make this script executable with
# sudo chmod +x update_vs_server.sh

# Create a symlink in /usr/local/bin (in system PATH)
# sudo ln -s /path/to/update_vs_server.sh /usr/local/bin/update-vs-server

# Check if script is run with sudo
if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root or with sudo"
        exit 1
fi

# Define variables
SERVER_DIR="/home/vintagestory"
DATE=$(date +%Y%m%d_%H%M%S)
VERSION=${1:-"1.20.11"}  # Use provided version or default to 1.20.11
TARBALL="vs_server_linux-x64_${VERSION}.tar.gz"
DOWNLOAD_URL="https://cdn.vintagestory.at/gamefiles/stable/${TARBALL}"

# Log function
log() {
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Error handling
set -e # Exit on error
trap 'log "Error occurred at the line $LINENO. Exiting."; exit 1' ERR

# Start the update process
log "Starting Vintage Story server update to version ${VERSION}"

# Navigate to the server directory
cd "${SERVER_DIR}"
log "Changed to directory: ${SERVER_DIR}"

# Stop the server service if it's running
if systemctl is-active --quiet vs_server; then
        log "Stopping vs_server service..."
        systemctl stop vs_server
        sleep 5 # Wait for service to stop
fi

if [ -d "server" ]; then
        log "Creating backup of current server directory..."
        mv server "server_backup_${DATE}"
        log "Backup created: server_backup_${DATE}"
else
        log "No existing server directory found, creating a new one"
fi

# Create a new server directory
log "Creating new server directory..."
mkdir -p server
cd server
log "Changed to directory: ${SERVER_DIR}/server"

# Download the server files
log "Downloading server version ${VERSION}..."
wget -q --show-progress "${DOWNLOAD_URL}"
if [ $? -ne 0 ]; then
        log "Error: Download failed. Please check the version number and try again."
        exit 1
fi
log "Download completed."

# Extract the archive
log "Extracting server files..."
tar xzf "${TARBALL}"
log "Extraction completed"

# Set executable permissions for server.sh
log "Setting executable permissions on server.sh..."
chmod +x server.sh
log "Permissions set"

# Remove the tarball to save space
log "Cleaning up downloaded archive..."
rm "${TARBALL}"
log "Cleanup completed"

# Set correct ownership
log "Setting ownership to vintagestory user..."
chown -R vintagestory:vintagestory .
log "Ownership changed"

# Start the server service
log "Starting vs_server service..."
systemctl start vs_server
log "Server service started"

# Check if the service started correctly
if systemctl is-active --quiet vs_server; then
    log "Vintage Story server updated successfully and service is running."
else
    log "Warning: Service failed to start. Please check logs with 'journalctl -u vs_server'"
fi

log "Update process completed!!!"