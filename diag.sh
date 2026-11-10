#!/bin/bash
# REALITY 连通性诊断 (在装好脚本的服务器上跑)
red='\e[31m'; green='\e[92m'; yellow='\e[93m'; none='\e[0m'
ok(){ echo -e "${green}OK${none}  $*"; }
bad(){ echo -e "${red}FAIL${none} $*"; }
warn(){ echo -e "${yellow}WARN${none} $*"; }

echo "===== 1. 内核与服务 ====="
for c in xray v2ray; do
  if command -v $c >/dev/null 2>&1; then
    st=$(systemctl is-active $c 2>/dev/null)
    [[ "$st" == "active" ]] && ok "服务 $c 运行中" || bad "服务 $c 未运行 (状态:$st)"
  fi
done

echo
echo "===== 2. 监听端口 ====="
ss -tlnp 2>/dev/null | grep -E 'xray|v2ray' || echo "(未发现监听)"

echo
echo "===== 3. 配置校验 ====="
for d in /etc/xray /etc/v2ray; do
  [[ -f $d/config.json ]] || continue
  echo "--- $d ---"
  c=$(basename $d)
  $c bin run -test -c $d/config.json 2>&1 | tail -3
done

echo
echo "===== 4. REALITY 参数 (核对客户端链接) ====="
found=0
for d in /etc/xray /etc/v2ray; do
  [[ -d $d/conf ]] || continue
  for f in $d/conf/*.json; do
    [[ -f "$f" ]] || continue
    sec=$(jq -r '.inbounds[0].streamSettings.security // empty' "$f" 2>/dev/null)
    [[ "$sec" == "reality" ]] || continue
    found=1
    echo "--- $f ---"
    jq -c '.inbounds[0] | {port, dest:.streamSettings.realitySettings.dest, serverNames:.streamSettings.realitySettings.serverNames, publicKey:.streamSettings.realitySettings.publicKey, shortIds:.streamSettings.realitySettings.shortIds}' "$f"
  done
done
[[ $found == 0 ]] && warn "没找到 REALITY 配置"

echo
echo "===== 5. dest 伪装站可达性 ====="
for d in /etc/xray /etc/v2ray; do
  [[ -d $d/conf ]] || continue
  for f in $d/conf/*.json; do
    [[ -f "$f" ]] || continue
    sec=$(jq -r '.inbounds[0].streamSettings.security // empty' "$f" 2>/dev/null)
    [[ "$sec" == "reality" ]] || continue
    dest=$(jq -r '.inbounds[0].streamSettings.realitySettings.dest // empty' "$f")
    [[ -z "$dest" ]] && continue
    code=$(curl -sI --max-time 6 "https://$dest" -o /dev/null -w "%{http_code}" 2>/dev/null)
    [[ "$code" =~ ^(200|30[0-9]|403|404)$ ]] && ok "dest $dest -> $code" || bad "dest $dest -> $code (服务器到伪装站不通)"
  done
done

echo
echo "===== 6. 出口能否上网 ====="
code=$(curl -sI --max-time 8 https://www.google.com -o /dev/null -w "%{http_code}" 2>/dev/null)
[[ "$code" =~ ^(200|30[0-9])$ ]] && ok "google -> $code" || bad "google -> $code (服务器出口不通)"

echo
echo "===== 7. 最近日志 ====="
for c in xray v2ray; do
  command -v $c >/dev/null 2>&1 || continue
  echo "--- $c ---"
  journalctl -u $c -n 15 --no-pager 2>/dev/null | tail -10
done
