#!/bin/bash

# 配置参数
RELEASE_URL="https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz"
INSTALL_DIR="/opt/nginx"
BIN_LINK="/usr/local/bin/nginx"
TMP_DIR="/tmp/nginx_install"
LOGFILE="/tmp/nginx_install.log"

echo "[nginx-install] 开始安装 Nginx..." | tee "$LOGFILE"

# 创建临时目录
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

# 下载构建包
echo "[nginx-install] 下载构建包..." | tee -a "$LOGFILE"
wget -O nginx-build.tar.gz "$RELEASE_URL" >> "$LOGFILE" 2>&1

# 解压
echo "[nginx-install] 解压构建包..." | tee -a "$LOGFILE"
tar -zxvf nginx-build.tar.gz >> "$LOGFILE" 2>&1

# 安装到指定目录
echo "[nginx-install] 安装到 $INSTALL_DIR..." | tee -a "$LOGFILE"
sudo mkdir -p "$INSTALL_DIR/sbin"
sudo cp output/nginx/nginx "$INSTALL_DIR/sbin/nginx"

# 创建软链接
echo "[nginx-install] 创建软链接到 $BIN_LINK..." | tee -a "$LOGFILE"
sudo ln -sf "$INSTALL_DIR/sbin/nginx" "$BIN_LINK"

# 验证安装
echo "[nginx-install] 验证安装..." | tee -a "$LOGFILE"
nginx -v 2>&1 | tee -a "$LOGFILE"

echo "[nginx-install] 安装完成 ✅" | tee -a "$LOGFILE"
