# 🚀 Nginx Build Auto

自动从官方源码构建 Nginx，并上传到 GitHub Releases。构建版本包含常用模块，适用于嵌入式设备、自定义部署或轻量级环境（如 QNAP NAS）。

---

## 📦 构建产物

最新构建版本：

🔗 [nginx-build.tar.gz](https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz)

包含内容：

output/ └── nginx/ └── nginx # 编译后的可执行文件


---

## 🛠️ 构建参数

使用 GitHub Actions 自动构建，启用以下模块：

- ✅ HTTP/2 (`--with-http_v2_module`)
- ✅ SSL (`--with-http_ssl_module`)
- ✅ Gzip 静态压缩 (`--with-http_gzip_static_module`)
- ✅ PCRE 正则支持 (`--with-pcre`)

构建脚本位于 `.github/workflows/build-and-release.yml`

---

## 📥 一键安装脚本

你可以使用以下脚本自动下载并安装 Nginx 到 `/opt/nginx`：

```bash
#!/bin/bash

RELEASE_URL="https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz"
INSTALL_DIR="/opt/nginx"
BIN_LINK="/usr/local/bin/nginx"
TMP_DIR="/tmp/nginx_install"
LOGFILE="/tmp/nginx_install.log"

echo "[nginx-install] 开始安装 Nginx..." | tee "$LOGFILE"
mkdir -p "$TMP_DIR" && cd "$TMP_DIR"
wget -O nginx-build.tar.gz "$RELEASE_URL" >> "$LOGFILE" 2>&1
tar -zxvf nginx-build.tar.gz >> "$LOGFILE" 2>&1
sudo mkdir -p "$INSTALL_DIR/sbin"
sudo cp output/nginx/nginx "$INSTALL_DIR/sbin/nginx"
sudo ln -sf "$INSTALL_DIR/sbin/nginx" "$BIN_LINK"
nginx -v 2>&1 | tee -a "$LOGFILE"
echo "[nginx-install] 安装完成 ✅" | tee -a "$LOGFILE"

📂 默认配置建议
创建最小配置文件 /opt/nginx/conf/nginx.conf：

worker_processes  1;
events {
    worker_connections  1024;
}
http {
    server {
        listen       80;
        server_name  localhost;

        location / {
            return 200 'Nginx is running!';
        }
    }
}

启动命令：

nginx -c /opt/nginx/conf/nginx.conf

🧩 自定义构建
如需修改版本或模块，请编辑：

NGINX_VERSION="1.25.3"
./configure ...

位于 .github/workflows/build-and-release.yml
