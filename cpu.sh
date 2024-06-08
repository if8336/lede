#安装stress
#
sudo yum install epel-release # 如果您尚未安装 EPEL 存储库，请先执行此命令
sudo yum install stress
stress --version
#
#
apt-get install stress bc
脚本

#!/bin/bash

while true; do
  # 计算当前CPU占用率
  cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

  # 如果占用率低于30%，则执行一个占用CPU的命令
  if (($(echo "$cpu_usage < 30.0" | bc -l))); then
    echo "cpu usage is less than 30%, running stress test..."
    stress --cpu 1 --timeout 5s >/dev/null 2>&1 &
  fi

  # 如果占用率高于50%，则杀死一个占用CPU的进程
  if (($(echo "$cpu_usage > 50.0" | bc -l))); then
    echo "cpu usage is greater than 50%, killing stress test..."
    pkill -f "stress --cpu 1"
  fi

  # 等待一段时间，再次计算CPU占用率
  sleep 1
done




#启动
#!/bin/bash
nohup ./cpu.sh 2>&1 &


#停止
#!/bin/bash
pkill -f cpu.sh

#查看cpu占用率
top -bn1 | grep "Cpu(s)"


#!/bin/bash

# 指定米家网关的 IP 地址
GATEWAY_IP="192.168.0.123"

# RGB 彩灯颜色值（红色）
RGB_VALUE="16711680"

# 使用 miio 命令开启 RGB 彩灯
miio --ip $GATEWAY_IP --method call --device-type gateway --method-set rgb --arguments 16711680

