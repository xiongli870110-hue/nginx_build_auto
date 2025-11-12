#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_DIR="/opt/ttyd"
BIN_NAME="ttyd"
LOCAL_BIN="/usr/local/bin/$BIN_NAME"
OFFLINE_PACKAGE="$SCRIPT_DIR/jkyd.x86_64"
REMOTE_URL="https://gitee.com/rakerose/gist/raw/master/jkyd.x86_64"
SERVICE_FILE="/etc/systemd/system/ttyd.service"
LOG_DIR="/tmp/logs"
LOGFILE="$LOG_DIR/ttyd-install.log"

mkdir -p "$LOG_DIR"
touch "$LOGFILE"

log() {
  echo "[$(date '+%F %T')] $1" | tee -a "$LOGFILE"
}

uninstall_previous() {
  log "Uninstalling previous ttyd installation..."
  systemctl stop ttyd.service 2>/dev/null || true
  systemctl disable ttyd.service 2>/dev/null || true
  rm -f "$SERVICE_FILE"
  rm -f "$INSTALL_DIR/$BIN_NAME" "$LOCAL_BIN"
  log "Previous ttyd uninstalled."
}

install_new() {
  log "Checking for offline package..."
  mkdir -p "$INSTALL_DIR"
  if [ -f "$OFFLINE_PACKAGE" ]; then
    log "Offline package found. Installing from local file."
    cp "$OFFLINE_PACKAGE" "$INSTALL_DIR/$BIN_NAME"
  else
    log "No offline package found. Downloading from remote..."
    curl -L -o "$OFFLINE_PACKAGE" "$REMOTE_URL" || { log "Download failed!"; exit 1; }
    cp "$OFFLINE_PACKAGE" "$INSTALL_DIR/$BIN_NAME"
  fi

  chmod +x "$INSTALL_DIR/$BIN_NAME"
  ln -sf "$INSTALL_DIR/$BIN_NAME" "$LOCAL_BIN"

  log "Creating systemd service..."
  cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=ttyd Web Terminal
After=network.target

[Service]
ExecStart=$LOCAL_BIN --writable -p 7681 -c admin:admin bash
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

  log "Reloading systemd and enabling ttyd service..."
  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable ttyd.service
  systemctl start ttyd.service

  # °æ±¾¼ì²â
  if "$LOCAL_BIN" --version >/dev/null 2>&1; then
    VERSION=$("$LOCAL_BIN" --version)
    log "[OK] ttyd installed successfully. Version: $VERSION"
  else
    log "[ERROR] ttyd installation failed or binary not working!"
    exit 1
  fi

  # ×ÔÆô¶¯¼ì²â
  if systemctl is-enabled ttyd.service >/dev/null 2>&1; then
    log "[OK] ttyd service is enabled for auto-start on boot."
  else
    log "[WARN] ttyd service is NOT enabled for auto-start. Please run: systemctl enable ttyd.service"
  fi
}

case "$1" in
  install)
    uninstall_previous
    install_new
    ;;
  uninstall)
    uninstall_previous
    ;;
  reinstall)
    uninstall_previous
    install_new
    ;;
  *)
    echo "Usage: $0 {install|uninstall|reinstall}"
    exit 1
    ;;
esac
