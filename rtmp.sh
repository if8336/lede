#!/bin/bash
#key=$(cat bili.key)
#ychannel=$(cat ychannel)
url=''

while getopts ":t:c:y:" opt; do
  case ${opt} in
    t ) # 处理 -t 参数
      mode="t"
      echo "使用 twitch 模式"
      url='https://www.twitch.tv/'

      ;;
    c ) # 处理 -c 参数
      channel="$OPTARG"
      echo "-c 参数，值为 $channel，channel 为 $channel"
      ;;
   y ) # 处理 - 参数
        mode="t"
        echo "使用 youtube 模式"
        url='https://www.youtube.com/watch?v='

    \? ) # 处理无效参数
      echo "无效参数: -$OPTARG" 1>&2
      exit 1
      ;;
    : ) # 处理缺少参数
      echo "缺少参数: -$OPTARG" 1>&2
      exit 1
      ;;
  esac
done

echo $url$channel
#
#yt-dlp  --user-agent  \
#'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36' \
#	-o - $url$ychannel | ffmpeg  -re -i - -c:v copy -c:a copy -bsf:a aac_adtstoasc  -f flv "rtmp://live-push.bilivideo.com/live-bvc/"$key
#echo $! > id
