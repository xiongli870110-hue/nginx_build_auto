# 🚀 Nginx Build Auto

自动从官方源码构建 Nginx，并上传到 GitHub Releases。构建版本包含常用模块，适用于嵌入式设备、自定义部署或轻量级环境（如 QNAP NAS）。

---

*** 安装nginx如此简单 ***

进入主机输入的命令如下：
sudo -i
cd /tmp
nano install_nginx_from_github_qanp.sh
chmod +x ./install_nginx_from_github_qanp.sh
./install_nginx_from_github_qanp.sh

会自动执行，成功的后输出以下信息：
[nginx-install] 主程序位置识别为：/tmp/nginx-build/output/nginx/sbin
[nginx-install] 安装到 /opt/nginx...
[nginx-install] 创建软链接...
[nginx-install] 创建必要目录...
[nginx-install] 创建日志文件...
[nginx-install] 创建默认配置文件 nginx.conf...
[nginx-install] 创建 mime.types（最小版本）...
[nginx-install] 创建默认首页...
[nginx-install] 验证配置...
nginx: the configuration file /opt/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/nginx/conf/nginx.conf test is successful
[nginx-install] 启动 nginx...
[nginx-install] 安装完成 ✅

自己动手再测试一下：
root@instance-20250825-032000:/tmp# which nginx
/usr/local/bin/nginx
root@instance-20250825-032000:/tmp# nginx -t
nginx: the configuration file /opt/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/nginx/conf/nginx.conf test is successful

浏览器打开你的ip地址，能看看测试网页：
Welcome to nginx @ instance-20250825-032000



## 📦 构建产物

最新构建版本：

🔗 [nginx-build.tar.gz](https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz)

包含内容：

output/ 
   └── nginx/ 
      └── nginx # 编译后的可执行文件


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

set -e

echo "[nginx-install] 开始安装 Nginx（使用预编译包）..."

INSTALL_DIR=/opt/nginx
CONF_DIR=$INSTALL_DIR/conf
LOG_DIR=$INSTALL_DIR/logs
SSL_DIR=$INSTALL_DIR/ssl
HTML_DIR=$INSTALL_DIR/html
RELEASE_URL=https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3-ssl/nginx-build.tar.gz
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

# 自动选择系统存在的用户（优先 httpdusr > admin > raker）
for U in guest admin ubuntu; do
  if id "$U" >/dev/null 2>&1; then
    NGINX_USER="$U"
    break
  fi
done
NGINX_USER=${NGINX_USER:-admin}

echo "[nginx-install] 创建默认配置文件 nginx.conf..."
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


启动命令：

nginx -c /opt/nginx/conf/nginx.conf

🧩 自定义构建
如需修改版本或模块，请编辑：

NGINX_VERSION="1.25.3"
./configure ...

位于 .github/workflows/build-and-release.yml
