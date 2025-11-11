
# 🚀 Nginx Build Auto

自动从官方源码构建 Nginx，并上传到 GitHub Releases。构建版本包含常用模块，适用于嵌入式设备、自定义部署或轻量级环境（如 QNAP NAS）。

## 📖 项目背景

本项目旨在解决威联通NAS重启后重置`/etc/`目录导致无法常规安装Nginx的问题。通过此方法，可以在威联通NAS上成功部署个人博客。

**已验证环境：**
- ✅ QNAP NAS（已释放80、443端口）
- ✅ Ubuntu 系统
- ✅ 其他 Linux 发行版

> 💡 **提示**：如果您的Linux系统比较老旧，建议使用 `install_nginx_from_github_qanp.sh` 进行安装。

## ⭐️ 快速安装

### 🧭 步骤一：执行安装命令

```bash
sudo -i
cd /tmp
nano install_nginx_from_github_qanp.sh
chmod +x ./install_nginx_from_github_qanp.sh
./install_nginx_from_github_qanp.sh
```

### ⚙️ 安装过程输出示例

```
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
```

### 🧪 步骤二：验证安装

```bash
# 检查nginx位置
which nginx

# 测试配置文件
nginx -t

# 输出示例：
# /usr/local/bin/nginx
# nginx: the configuration file /opt/nginx/conf/nginx.conf syntax is ok
# nginx: configuration file /opt/nginx/conf/nginx.conf test is successful
```

### 🌐 步骤三：访问测试

打开浏览器访问您的服务器IP地址，将显示：
```
Welcome to nginx @ [您的服务器主机名]
```

## 📦 构建产物

**最新构建版本：**
🔗 [nginx-build.tar.gz](https://github.com/xiongli870110-hue/nginx_build_auto/releases/download/nginx-1.25.3/nginx-build.tar.gz)

**包含内容：**
```
output/
   └── nginx/
      └── nginx # 编译后的可执行文件
```

## 🛠️ 构建参数

使用 GitHub Actions 自动构建，启用以下模块：

- ✅ HTTP/2 (`--with-http_v2_module`)
- ✅ SSL (`--with-http_ssl_module`)
- ✅ Gzip 静态压缩 (`--with-http_gzip_static_module`)
- ✅ PCRE 正则支持 (`--with-pcre`)

**构建脚本位置：** `.github/workflows/build-and-release.yml`

## 📥 一键安装脚本

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

# 自动选择系统存在的用户
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
```

## 🚀 启动命令

```bash
nginx -c /opt/nginx/conf/nginx.conf
```

## 🧩 自定义构建

如需修改版本或模块，请编辑构建脚本中的以下参数：

```yaml
NGINX_VERSION="1.25.3"
./configure ...
```

**构建脚本位置：** `.github/workflows/build-and-release.yml`

---

**项目特点：**
- 🎯 专为特殊环境（如QNAP NAS）优化
- 📦 包含常用模块，开箱即用
- 🔧 支持自定义构建参数
- ✅ 多平台兼容测试
