#!/bin/bash

set -e

echo "[nginx-install] 开始安装 Nginx（使用预编译包）..."

INSTALL_DIR=/opt/nginx
CONF_DIR=$INSTALL_DIR/conf
LOG_DIR=$INSTALL_DIR/logs
SSL_DIR=$INSTALL_DIR/ssl
RELEASE_URL=https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz
RELEASE_TMP=/tmp/nginx-build.tar.gz
SRC_TMP=/tmp/nginx-src
SRC_URL=http://nginx.org/download/nginx-1.25.3.tar.gz

echo "[nginx-install] 下载预编译包..."
wget -O $RELEASE_TMP "$RELEASE_URL"

echo "[nginx-install] 解压到安装目录..."
mkdir -p $INSTALL_DIR
tar -zxvf $RELEASE_TMP -C $INSTALL_DIR

echo "[nginx-install] 创建必要目录..."
mkdir -p $CONF_DIR $LOG_DIR $SSL_DIR

echo "[nginx-install] 创建日志文件..."
touch $LOG_DIR/error.log
touch $LOG_DIR/access.log

echo "[nginx-install] 检查 mime.types..."
if [ ! -f "$CONF_DIR/mime.types" ]; then
  echo "[nginx-install] mime.types 缺失，尝试从官方源码提取..."
  mkdir -p $SRC_TMP
  wget -O $SRC_TMP/nginx.tar.gz $SRC_URL
  tar -zxvf $SRC_TMP/nginx.tar.gz -C $SRC_TMP
  cp $SRC_TMP/nginx-1.25.3/conf/mime.types $CONF_DIR/
  echo "[nginx-install] 已复制 mime.types ✅"
else
  echo "[nginx-install] mime.types 已存在，跳过复制 ✅"
fi

echo "[nginx-install] 检查 nginx.conf 是否存在..."
if [ ! -f "$CONF_DIR/nginx.conf" ]; then
  echo "[警告] 未找到 nginx.conf，请手动提供配置文件到 $CONF_DIR/"
else
  echo "[nginx-install] 验证配置..."
  $INSTALL_DIR/sbin/nginx -t || echo "[nginx-install] 配置验证失败，请检查 nginx.conf"
fi

echo "[nginx-install] 创建软链接..."
ln -sf $INSTALL_DIR/sbin/nginx /usr/local/bin/nginx

echo "[nginx-install] 安装完成 ✅"
