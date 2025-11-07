#!/bin/bash
set -e

# 安装参数
INSTALL_DIR="/opt/ttyd"
BIN_LINK="/usr/local/bin/ttyd"
TARBALL="ttyd-build.tar.gz"
DOWNLOAD_URL="https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/ttyd-1.7.7-qnap/ttyd-build.tar.gz"

# 检查是否已安装
if command -v ttyd >/dev/null 2>&1; then
    echo "✅ ttyd 已安装，退出安装。"
    exit 0
fi

# 检查是否已有离线包
if [ -f "$TARBALL" ]; then
    echo "📦 检测到本地离线包 $TARBALL，跳过下载。"
else
    echo "🌐 未检测到离线包，开始下载..."
    curl -L "$DOWNLOAD_URL" -o "$TARBALL"
fi

# 解压并安装
echo "📂 解压并安装到 $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
tar -xzf "$TARBALL" -C "$INSTALL_DIR" --strip-components=1

# 建立软链接
echo "🔗 建立软链接到 $BIN_LINK..."
sudo ln -sf "$INSTALL_DIR/ttyd" "$BIN_LINK"

# 设置执行权限（保险起见）
chmod +x "$INSTALL_DIR/ttyd"

# 验证安装
echo "✅ 安装完成，版本信息如下："
ttyd --version
