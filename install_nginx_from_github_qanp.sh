#!/bin/bash

set -e

echo "[nginx-install] 开始安装 Nginx（使用预编译包）..."

INSTALL_DIR=/opt/nginx
CONF_DIR=$INSTALL_DIR/conf
LOG_DIR=$INSTALL_DIR/logs
SSL_DIR=$INSTALL_DIR/ssl
HTML_DIR=$INSTALL_DIR/html
RELEASE_URL=https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz
RELEASE_TMP=/tmp/nginx-build.tar.gz
UNPACK_DIR=/tmp/nginx-build

# 下载预编译包（如缺失）
if [ -f "$RELEASE_TMP" ]; then
  echo "[nginx-install] 本地已存在 nginx-build.tar.gz，跳过下载 ✅"
else
  echo "[nginx-install] 下载预编译包..."
  wget -O "$RELEASE_TMP" "$RELEASE_URL"
fi

echo "[nginx-install] 解压预编译包..."
rm -rf "$UNPACK_DIR"
mkdir -p "$UNPACK_DIR"
tar -zxvf "$RELEASE_TMP" -C "$UNPACK_DIR"

# 自动查找 nginx 主程序
FOUND_NGINX=$(find "$UNPACK_DIR" -type f -name nginx -executable | head -n 1)

if [ -z "$FOUND_NGINX" ]; then
  echo "[错误] 未找到 nginx 主程序，安装失败 ❌"
  exit 1
fi

FOUND_DIR=$(dirname "$FOUND_NGINX")
echo "[nginx-install] 主程序位置识别为：$FOUND_DIR"

echo "[nginx-install] 安装到 $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cp -r "$FOUND_DIR"/* "$INSTALL_DIR/"

# 验证主程序是否存在
if [ ! -f "$INSTALL_DIR/nginx" ]; then
  echo "[错误] 安装后仍未找到 nginx 主程序，安装失败 ❌"
  exit 1
fi

echo "[nginx-install] 创建软链接..."
ln -sf "$INSTALL_DIR/nginx" /usr/local/bin/nginx

echo "[nginx-install] 创建必要目录..."
mkdir -p "$CONF_DIR" "$LOG_DIR" "$SSL_DIR" "$HTML_DIR"

echo "[nginx-install] 创建日志文件..."
touch "$LOG_DIR/access.log"
touch "$LOG_DIR/error.log"

echo "[nginx-install] 创建默认配置文件 nginx.conf..."
cat > "$CONF_DIR/nginx.conf" <<EOF
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

echo "[nginx-install] 创建 mime.types（最小版本）..."
cat > "$CONF_DIR/mime.types" <<EOF
types {
    text/html html htm;
    text/css css;
    application/javascript js;
    image/png png;
    image/jpeg jpg jpeg;
}
EOF

echo "[nginx-install] 创建默认首页..."
echo "<h1>Welcome to nginx @ $(hostname)</h1>" > "$HTML_DIR/index.html"

echo "[nginx-install] 验证配置..."
"$INSTALL_DIR/nginx" -t

echo "[nginx-install] 启动 nginx..."
"$INSTALL_DIR/nginx"

echo "[nginx-install] 安装完成 ✅"
