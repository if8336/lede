#!/bin/bash

# record_name需要提前创建好
# zone_id和原本的二级域名有关
record_name="v2.llnlywj.eu.org"
ZONE_ID="359059bd52c769a4d6166e8fb14a270f"

#基本不变
API_KEY="XVQ8XO2cvNnC_wHNSCC_cZlIhbGchDMV5VrVePuJ"

CLOUDFLARE_IP=$(curl -s https://ipv4.icanhazip.com)
echo 当前Cloudflare的IPv4地址为:
echo $CLOUDFLARE_IP
or_ip=$(cat /tmp/cloudflare_ip.txt)

# 判断ip地址是否变化
if [ "$CLOUDFLARE_IP" = "$or_ip" ]; then
  echo "IP地址未变化，不需要更新"
  exit 0
fi
echo "开始更新"
echo $CLOUDFLARE_IP > /tmp/cloudflare_ip.txt

RECORD_ID=$(curl -s \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records?name=${record_name}" |
  jq '.result[0].id')

RECORD_ID="${RECORD_ID//\"/}"

# 使用api更新DNS记录
echo "更新DNS记录"
echo "RECORD_ID: ${RECORD_ID}"
echo "ZONE_ID: ${ZONE_ID}"

curl --request PUT --url https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${RECORD_ID} \
  -H "Authorization: Bearer ${API_KEY}" \
  --header 'Content-Type: application/json' \
  --data '{"type":"A","name":"'${record_name}'","content":"'${CLOUDFLARE_IP}'"}'


