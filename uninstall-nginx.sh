#!/bin/bash
set -e

echo "[nginx-uninstall] ?? Starting Nginx uninstallation (custom build)..."

INSTALL_DIR=/opt/nginx
SERVICE_FILE=/etc/systemd/system/nginx-custom.service
SYMLINK_BIN=/usr/local/bin/nginx
UNPACK_DIR=/tmp/nginx-build

echo "[nginx-uninstall] Stopping and disabling systemd service..."
if systemctl list-unit-files | grep -q nginx-custom.service; then
  systemctl stop nginx-custom.service || true
  systemctl disable nginx-custom.service || true
fi

echo "[nginx-uninstall] Removing systemd service file..."
rm -f "$SERVICE_FILE"

echo "[nginx-uninstall] Removing installation directory..."
rm -rf "$INSTALL_DIR"

echo "[nginx-uninstall] Removing temporary unpack directory..."
rm -rf "$UNPACK_DIR"

echo "[nginx-uninstall] Removing nginx symlink..."
rm -f "$SYMLINK_BIN"

echo "[nginx-uninstall] Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed || true

echo "[nginx-uninstall] ? Uninstallation completed!"
echo "(If you manually modified /opt/nginx/conf, please back it up before running this script.)"
