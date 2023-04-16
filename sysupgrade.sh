#!/bin/zsh

# 切换到工作目录
cd ~/Downloads/update
# 记录日志
#exec &> >(tee -a "runner.log")

#路由器地址
ROUTER_IP="10.1.1.1"
# 软件仓库地址
REPO_URL="https://github.com/yjw8336/lede"
# 当前日期
CURRENT_DATE=$(date +%Y-%m%d%H%M%S)


# 检查是否有互联网连接
if ! curl -s -I -m 5 https://github.com/ > /dev/null ; then
    echo "网络连接失败，请检查网络后重试。"
    exit 1
fi
echo "网络连接正常"
# 检查是否有互联网连接
if ! ping -t 1 -W 1 ${ROUTER_IP} > /dev/null; then
    echo "路由器连接失败，请修改代码中router_ip项后重试。"
    exit 1
fi
echo "路由器连接正常"

# 通过重定向获取最终的下载地址
release_url=$(curl -s -L -o /dev/null -w '%{url_effective}' "${REPO_URL}/releases/latest")

# 从下载地址中获取版本号
latest_release=${release_url##*/}

# 下载固件
echo "正在下载固件 -->${REPO_URL}/releases/download/${latest_release}/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz"
# https://github.com/yjw8336/lede/releases/download/20230404-a8596c6/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz
#
wget "${REPO_URL}/releases/download/${latest_release}/openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz" -O ${CURRENT_DATE}.sysupgrade.img.gz  || exit 1

# 下载sha256sums
echo "正在下载sha256sums -->${REPO_URL}/releases/download/${latest_release}/sha256sums"
wget "${REPO_URL}/releases/download/${latest_release}/sha256sums" -O ${CURRENT_DATE}.sha256sums || exit 1


# 验证固件
checksum=$(shasum -a 256 ${CURRENT_DATE}.sysupgrade.img.gz | awk '{print $1}' )
orSum=$(cat ${CURRENT_DATE}.sha256sums | grep openwrt-rockchip-armv8-friendlyarm_nanopi-r2s-ext4-sysupgrade.img.gz | awk '{print $1}' )

if [ "$checksum" != "$orSum" ]; then
    echo "checksum error"
    echo "文件校验失败，请检查网络后重试。"
    echo "checksum: $checksum"
    echo "orSum: $orSum"
    exit 1
fi
 echo "文件校验成功"
 rm -rf ${CURRENT_DATE}.sha256sums

#备份当前配置信息
echo "正在备份当前配置信息"
ssh root@${ROUTER_IP} "sysupgrade -b /tmp/tmp/${CURRENT_DATE}.bak.tar.gz"

#下载备份文件
echo "正在下载备份文件"
scp -r root@${ROUTER_IP}:/tmp/tmp/${CURRENT_DATE}.bak.tar.gz ~/Downloads/update


# 上传固件
echo "正在上传固件"
scp -r ~/Downloads/update/${CURRENT_DATE}.sysupgrade.img.gz root@${ROUTER_IP}:/tmp/tmp/
# 执行更新
echo "正在执行更新,请耐心等待"

ssh root@${ROUTER_IP} "sysupgrade  /tmp/tmp/${CURRENT_DATE}.sysupgrade.img.gz"

echo "更新完成"
# 关闭日志
#exec >&-


