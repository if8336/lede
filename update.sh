#/bin/sh


# 检查是否有互联网连接
if ! ping -c 1 -W 1 github.com > /dev/null; then
    echo "网络连接失败，请检查网络后重试。"
    exit 1
fi

# 切换到工作目录
cd /tmp/tmp

# 更新软件包列表
sleep 10
# 当前软件版本
cur_ver=$(opkg list | grep "luci-app-aliyundrive-webdav - ")

echo "webdav当前版本号为:${cur_ver}"

# 软件仓库地址
repo_url="https://github.com/messense/aliyundrive-webdav"

# 通过重定向获取最终的下载地址
release_url=$(curl -s -L -o /dev/null -w '%{url_effective}' "${repo_url}/releases/latest")

# 从下载地址中获取版本号
latest_release=${release_url##*/}
# 去掉版本号前面的v
latest_release=${latest_release//v/}

echo "webdav最新版本号为:luci-app-aliyundrive-webdav - ${latest_release}"

# 比较版本号
if test "luci-app-aliyundrive-webdav - ${latest_release}" != "$cur_ver"; then
	echo "正在更新webdav..."

	# 更新webdav
	wget https://github.com/messense/aliyundrive-webdav/releases/download/v${latest_release}/aliyundrive-webdav_${latest_release}-1_aarch64_generic.ipk
	wget https://github.com/messense/aliyundrive-webdav/releases/download/v${latest_release}/luci-app-aliyundrive-webdav_${latest_release}_all.ipk
	wget https://github.com/messense/aliyundrive-webdav/releases/download/v${latest_release}/luci-i18n-aliyundrive-webdav-zh-cn_${latest_release}-1_all.ipk
	opkg install aliyundrive-webdav_${latest_release}-1_aarch64_generic.ipk
	opkg install luci-app-aliyundrive-webdav_${latest_release}_all.ipk
	opkg install luci-i18n-aliyundrive-webdav-zh-cn_${latest_release}-1_all.ipk
	echo "webdav更新完成！"
else
	echo "webdav是最新版，不需要更新..."
fi


echo "检查UU加速器"
if ! ps -ef | grep -v grep | grep uuplugin_monitor > /dev/null; then
	echo "正在安装UU加速器"

	# 安装UU加速器
	echo "正在安装uu加速器..."
	wget http://uu.gdl.netease.com/uuplugin-script/202012111056/install.sh -O install.sh
	/bin/sh install.sh openwrt $(uname -m)
	echo "UU加速器已安装！"

else
	echo "UU加速器正在运行..."
fi
