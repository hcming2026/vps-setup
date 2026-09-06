#!/bin/bash
#
# deploy-reality.sh
# VPS 一键部署脚本：BBR + 防火墙 + VLESS+Reality 节点
#
# 使用方法：
#   1. SSH 登录到 VPS（root 用户）
#   2. 运行：bash deploy-reality.sh
#
# 前置条件：
#   - Ubuntu 22.04 LTS 或 Debian 12
#   - root 权限
#   - 网络可访问 GitHub
#

set -e  # 遇到错误立即退出

echo "======================================"
echo "  VPS 一键部署脚本"
echo "  VLESS+Reality + BBR + Firewall"
echo "======================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    error "请使用 root 用户运行此脚本"
    exit 1
fi

# Step 1: 系统更新
info "Step 1/5: 更新系统..."
apt update && apt upgrade -y

# Step 2: 启用 BBR
info "Step 2/5: 启用 BBR 拥塞控制..."
if ! grep -q "tcp_congestion_control" /etc/sysctl.conf; then
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    info "BBR 已启用"
else
    warn "BBR 已配置，跳过"
fi

# 验证 BBR
if lsmod | grep -q bbr; then
    info "BBR 模块已加载 ✅"
else
    warn "BBR 模块未加载，请检查内核版本（需要 ≥ 4.9）"
fi

# Step 3: 配置防火墙
info "Step 3/5: 配置防火墙 (ufw)..."
apt install ufw -y > /dev/null 2>&1 || true

ufw --force reset > /dev/null 2>&1
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'VLESS-Reality'

# 询问是否启用 Hysteria 2（备用协议，需要 UDP 443）
read -p "是否启用 Hysteria 2 备用协议？(y/n, 默认 n): " ENABLE_HY2
if [ "$ENABLE_HY2" = "y" ] || [ "$ENABLE_HY2" = "Y" ]; then
    ufw allow 443/udp comment 'Hysteria-2'
    info "已开放 UDP 443（Hysteria 2）"
fi

ufw --force enable
info "防火墙已启用 ✅"

# Step 4: 安装 fail2ban
info "Step 4/5: 安装 fail2ban（防 SSH 爆破）..."
apt install fail2ban -y > /dev/null 2>&1
systemctl enable fail2ban
systemctl start fail2ban
info "fail2ban 已启动 ✅"

# Step 5: 部署 Reality 节点
info "Step 5/5: 部署 sing-box Reality 节点..."
warn "接下来会调用 sing-box 一键脚本，按提示选择："
echo ""
echo "  协议选择 → 输 1（VLESS-REALITY）"
echo "  端口 → 输 443"
echo "  伪装目标 → 输 www.apple.com"
echo "  其他 → 默认回车"
echo ""
read -p "按 Enter 继续..." dummy

bash <(curl -Ls https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)

echo ""
echo "======================================"
echo -e "${GREEN}  ✅ 部署完成！${NC}"
echo "======================================"
echo ""
echo "请保存脚本输出的："
echo "  1. 节点链接（vless://...）"
echo "  2. 二维码（手机扫码用）"
echo "  3. 配置文件路径"
echo ""
echo "下一步："
echo "  - Windows: 配置 Clash Verge Rev"
echo "  - iOS:     用 Shadowrocket 扫码"
echo "  - Android: 用 Karing / Hiddify 粘贴链接"
echo ""
echo "验证：访问 https://openai.com 看是否能打开"
echo ""
