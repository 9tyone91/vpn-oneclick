#!/bin/bash
# 在服务器上环回自测 REALITY 隧道 (服务器自己 -> 自己)
BIN=/etc/xray/bin/xray
[[ -x $BIN ]] || { echo "找不到 $BIN"; exit 1; }
cfg=$(grep -l 'reality' /etc/xray/conf/*.json 2>/dev/null | head -1)
[[ -z $cfg ]] && { echo "没找到 REALITY 配置"; exit 1; }
port=$(jq -r '.inbounds[0].port' "$cfg")
uuid=$(jq -r '.inbounds[0].settings.clients[0].id' "$cfg")
sni=$(jq -r '.inbounds[0].streamSettings.realitySettings.serverNames[0]' "$cfg")
pbk=$(jq -r '.inbounds[0].streamSettings.realitySettings.publicKey' "$cfg")
sid=$(jq -r '.inbounds[0].streamSettings.realitySettings.shortIds[0] // ""' "$cfg")
sport=$(shuf -i 20000-30000 -n1)
echo "配置: $cfg"
echo "port=$port"
echo "sni=$sni"
echo "shortId=[$sid]"
cat > /tmp/rt_client.json <<JSON
{"inbounds":[{"port":$sport,"listen":"127.0.0.1","protocol":"socks","settings":{"udp":false}}],"outbounds":[{"protocol":"vless","settings":{"vnext":[{"address":"127.0.0.1","port":$port,"users":[{"id":"$uuid","encryption":"none","flow":"xtls-rprx-vision"}]}]},"streamSettings":{"network":"tcp","security":"reality","realitySettings":{"serverName":"$sni","fingerprint":"chrome","publicKey":"$pbk","shortId":"$sid","spiderX":"/"}}}]}
JSON
$BIN run -c /tmp/rt_client.json >/tmp/rt_client.log 2>&1 &
pid=$!
sleep 2
echo "=== 环回测试 (服务器自己 -> 自己) ==="
code=$(curl -x socks5://127.0.0.1:$sport -sI --max-time 10 https://www.google.com -o /dev/null -w "%{http_code}" 2>/dev/null)
echo "google via proxy: $code"
if [[ "$code" =~ ^(200|30[0-9])$ ]]; then
  echo "✅ 服务器 + REALITY + VLESS + 出口 全通 —— 问题在客户端/外部链路"
else
  echo "❌ 隧道没通 —— 看日志:"; tail -8 /tmp/rt_client.log
fi
kill $pid 2>/dev/null
