#!/bin/bash
# 删除服务文件
rm -rf /data/nas_server/cmcc_svr
rm -rf /data/nas_server/baidu_svr
rm -rf /data/nas_server/wps_svr
rm -rf /ugreen/thunder/xunlei-pan/start.sh
# 停止正在运行的旧服务
pkill -u thunder
killall -9 baidu_svr
killall -9 wps_svr
killall -9 cmcc_svr

echo "服务已禁用完成，百度，wps，中国移动网盘会在重启后自动恢复,迅雷需要手动执行下列代码后重启。"
echo "cp /rom//ugreen/thunder/xunlei-pan/start.sh /ugreen/thunder/xunlei-pan/start.sh"
