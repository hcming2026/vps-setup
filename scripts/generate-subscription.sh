#!/bin/bash
#
# generate-subscription.sh
# 生成 Clash / Sing-box / V2Ray 订阅链接
# 让多个客户端用同一个 URL 拉取最新配置
#
# 使用方法：
#   1. 修改下面的 VPS_IP / UUID / PRIVATE_KEY / DOMAIN
#   2. bash scripts/generate-subscription.sh
#   3. 把输出的链接导入 Clash Verge Rev / Sing-box 客户端
#

set -e

# ============ 配置区 ============
VPS_IP="你的VPS_IP"
DOMAIN="你的域名-留空则用IP"
UUID="你的UUID"
PRIVATE_KEY=""           # Reality 私钥（暂时不需要这个脚本）
PUBLIC_KEY="你的REALITY公钥"
SHORT_ID="你的短ID"
HY2_PASSWORD="你的Hysteria2密码"
SERVER_NAME="www.apple.com"
# =================================

# 颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# 如果有域名就用域名，否则用 IP
if [ -n "$DOMAIN" ]; then
    REALITY_HOST=$DOMAIN
else
    REALITY_HOST=$VPS_IP
fi

echo "======================================"
echo "  生成 sing-box / Clash 订阅链接"
echo "======================================"
echo ""

# ============ 1. VLESS Reality 节点链接 ============
step "1/4: 生成 VLESS Reality 节点链接"

# vless://uuid@host:port?security=reality&pbk=...&sid=...&sni=...&fp=chrome&type=tcp&flow=xtls-rprx-vision#name

VLESSS_URL="vless://${UUID}@${VPS_IP}:443"
VLESSS_URL="${VLESSS_URL}?security=reality"
VLESSS_URL="${VLESSS_URL}&pbk=${PUBLIC_KEY}"
VLESSS_URL="${VLESSS_URL}&sid=${SHORT_ID}"
VLESSS_URL="${VLESSS_URL}&sni=${SERVER_NAME}"
VLESSS_URL="${VLESSS_URL}&fp=chrome"
VLESSS_URL="${VLESSS_URL}&type=tcp"
VLESSS_URL="${VLESSS_URL}&flow=xtls-rprx-vision"
VLESSS_URL="${VLESSS_URL}#VPS-Reality"

echo "VLESS Reality 节点链接："
echo "${VLESSS_URL}"
echo ""

# Base64 编码（用于 Sing-box 订阅）
VLESSS_BASE64=$(echo -n "${VLESSS_URL}" | base64 -w 0)

# ============ 2. Hysteria 2 节点链接 ============
step "2/4: 生成 Hysteria 2 节点链接"

HY2_DOMAIN="hy2.${DOMAIN}"
HY2_URL="hysteria2://${HY2_PASSWORD}@${HY2_DOMAIN}:8443"
HY2_URL="${HY2_URL}?sni=${HY2_DOMAIN}"
HY2_URL="${HY2_URL}&obfs=salamander"
HY2_URL="${HY2_URL}&obfs-password="
HY2_URL="${HY2_URL}#VPS-Hysteria2"

echo "Hysteria 2 节点链接（需要域名）："
echo "${HY2_URL}"
echo ""

# ============ 3. Clash YAML 配置 ============
step "3/4: 生成 Clash YAML 配置"

CLASH_YAML=$(cat <<EOF
port: 7890
socks-port: 7891
allow-lan: false
mode: rule
log-level: info
external-controller: 127.0.0.1:9090

proxies:
  - name: "VPS-Reality"
    type: vless
    server: ${VPS_IP}
    port: 443
    uuid: ${UUID}
    flow: xtls-rprx-vision
    tls: true
    servername: ${SERVER_NAME}
    reality-opts:
      public-key: ${PUBLIC_KEY}
      short-id: ${SHORT_ID}
    client-fingerprint: chrome

proxy-groups:
  - name: "🚀 节点选择"
    type: select
    proxies:
      - VPS-Reality
      - DIRECT

  - name: "♻️ 自动选择"
    type: url-test
    url: "http://www.gstatic.com/generate_204"
    interval: 300
    tolerance: 50
    proxies:
      - VPS-Reality

rules:
  - GEOIP,CN,DIRECT
  - MATCH,🚀 节点选择

dns:
  enable: true
  ipv6: false
  enhanced-mode: fake-ip
  nameserver:
    - https://1.1.1.1/dns-query
    - https://8.8.8.8/dns-query
  nameserver-policy:
    "+.cn": [223.5.5.5, 119.29.29.29]
EOF
)

echo "Clash YAML 配置已生成（保存为 clash-config.yaml）："
echo ""
echo "${CLASH_YAML}" | head -20
echo "..."

# 保存到文件
echo "${CLASH_YAML}" > /tmp/clash-config.yaml
echo ""
info "已保存到 /tmp/clash-config.yaml"
echo ""

# ============ 4. 输出二维码 ============
step "4/4: 生成二维码（手机扫码用）"

if command -v qrencode &> /dev/null; then
    echo "${VLESSS_URL}" | qrencode -o /tmp/reality-qr.png -s 8
    info "Reality 二维码已保存到 /tmp/reality-qr.png"

    if [ -n "$HY2_PASSWORD" ]; then
        echo "${HY2_URL}" | qrencode -o /tmp/hy2-qr.png -s 8
        info "Hysteria 2 二维码已保存到 /tmp/hy2-qr.png"
    fi
else
    warn "未安装 qrencode，跳过二维码生成"
    info "安装命令：apt install qrencode -y"
fi

# ============ 5. 输出订阅链接（base64 编码） ============
echo ""
echo "======================================"
echo -e "${YELLOW}  📋 订阅链接汇总${NC}"
echo "======================================"
echo ""

echo "Sing-box 订阅链接（base64 编码 vless 链接）："
echo "${VLESSS_BASE64}"
echo ""

echo "Clash 订阅链接（base64 编码 YAML）："
echo "$(echo -n "${CLASH_YAML}" | base64 -w 0)"
echo ""

echo "======================================"
echo "✅ 完成！"
echo "======================================"
echo ""
echo "客户端配置："
echo "  Clash Verge Rev → Profiles → 粘贴 vless 链接或 YAML"
echo "  Shadowrocket → 扫码 / 粘贴 vless 链接"
echo "  Karing → 粘贴订阅链接"
echo ""
echo "提示：把上面的链接保存到 GitHub / Notion，下次换设备直接用。"
