#!/bin/bash
set -e

echo "[nginx-install] Starting Nginx installation (precompiled package)..."

# Get the current script directory
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

INSTALL_DIR=/opt/nginx
CONF_DIR=$INSTALL_DIR/conf
LOG_DIR=$INSTALL_DIR/logs
SSL_DIR=$INSTALL_DIR/ssl
HTML_DIR=$INSTALL_DIR/html
RELEASE_NAME=nginx-build.tar.gz
RELEASE_URL=https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3-qnap/${RELEASE_NAME}
RELEASE_LOCAL="${SCRIPT_DIR}/${RELEASE_NAME}"
UNPACK_DIR=/tmp/nginx-build

# Check for local package in script directory
if [ -f "$RELEASE_LOCAL" ]; then
  echo "[nginx-install] Found nginx-build.tar.gz next to script ✅"
else
  echo "[nginx-install] Downloading nginx-build.tar.gz to script directory..."
  wget -O "$RELEASE_LOCAL" "$RELEASE_URL"
fi

echo "[nginx-install] Extracting package..."
rm -rf "$UNPACK_DIR"
mkdir -p "$UNPACK_DIR"
tar -zxvf "$RELEASE_LOCAL" -C "$UNPACK_DIR"

# Locate nginx binary
FOUND_NGINX=$(find "$UNPACK_DIR" -type f -name nginx -executable | head -n 1)

if [ -z "$FOUND_NGINX" ]; then
  echo "[error] Nginx binary not found, installation failed ❌"
  exit 1
fi

FOUND_DIR=$(dirname "$FOUND_NGINX")
echo "[nginx-install] Binary located at: $FOUND_DIR"

echo "[nginx-install] Installing to $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$FOUND_DIR"/* "$INSTALL_DIR/"

# Verify installation
if [ ! -f "$INSTALL_DIR/nginx" ]; then
  echo "[error] Nginx binary missing after install ❌"
  exit 1
fi

echo "[nginx-install] Creating symlink..."
ln -sf "$INSTALL_DIR/nginx" /usr/local/bin/nginx

echo "[nginx-install] Creating required directories..."
mkdir -p "$CONF_DIR" "$LOG_DIR" "$SSL_DIR" "$HTML_DIR"

echo "[nginx-install] Creating log files..."
touch "$LOG_DIR/access.log"
touch "$LOG_DIR/error.log"

# Auto-select system user
for U in guest admin ubuntu; do
  if id "$U" >/dev/null 2>&1; then
    NGINX_USER="$U"
    break
  fi
done
NGINX_USER=${NGINX_USER:-admin}

echo "[nginx-install] Creating default nginx.conf..."
cat > "$CONF_DIR/nginx.conf" <<EOF
user $NGINX_USER;

worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    access_log  logs/access.log;
    error_log   logs/error.log;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }
    }
}
EOF

echo "[nginx-install] Creating minimal mime.types..."
cat > "$CONF_DIR/mime.types" <<EOF
types {
    text/html html htm;
    text/css css;
    application/javascript js;
    image/png png;
    image/jpeg jpg jpeg;
}
EOF

echo "[nginx-install] Creating default homepage..."
echo "<h1>Welcome to nginx @ $(hostname)</h1>" > "$HTML_DIR/index.html"

echo "[nginx-install] Validating configuration..."
"$INSTALL_DIR/nginx" -t

echo "[nginx-install] Starting nginx manually..."
"$INSTALL_DIR/nginx"

### === Add systemd autostart === ###
echo "[nginx-install] Creating systemd service file..."
cat > /etc/systemd/system/nginx-custom.service <<EOF
[Unit]
Description=Custom Nginx Service
After=network.target

[Service]
ExecStart=$INSTALL_DIR/nginx -c $CONF_DIR/nginx.conf
ExecReload=/bin/kill -s HUP \$MAINPID
ExecStop=/bin/kill -s QUIT \$MAINPID
Restart=always
PIDFile=/run/nginx.pid

[Install]
WantedBy=multi-user.target
EOF

echo "[nginx-install] Enabling and starting nginx-custom.service..."
systemctl daemon-reload
systemctl enable nginx-custom.service
systemctl start nginx-custom.service

echo "[nginx-install] ✅ Nginx installation and autostart setup complete"
