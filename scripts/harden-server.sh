#!/bin/bash
#
# harden-server.sh
# 服务器基础加固脚本：用户管理 + SSH 安全 + 自动更新
#
# 使用方法：
#   1. 以 root 身份 SSH 登录 VPS
#   2. 运行：bash harden-server.sh
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "请使用 root 用户运行此脚本"
    exit 1
fi

echo "======================================"
echo "  服务器基础加固脚本"
echo "======================================"

# Step 1: 创建普通用户
info "Step 1/6: 创建普通用户..."

if id "deploy" &>/dev/null; then
    warn "用户 'deploy' 已存在，跳过"
else
    read -p "输入新用户名（默认 deploy）: " NEW_USER
    NEW_USER=${NEW_USER:-deploy}
    adduser "$NEW_USER"
    usermod -aG sudo "$NEW_USER"
    info "用户 $NEW_USER 已创建并加入 sudo 组"
fi

# Step 2: 配置 SSH 密钥
info "Step 2/6: 配置 SSH 公钥..."
SSH_DIR="/home/$NEW_USER/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

warn "请将你的公钥（id_ed25519.pub 内容）粘贴到下面"
read -p "粘贴公钥后按 Enter: " PUBLIC_KEY

if [ -n "$PUBLIC_KEY" ]; then
    echo "$PUBLIC_KEY" > "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/authorized_keys"
    chown -R "$NEW_USER:$NEW_USER" "$SSH_DIR"
    info "公钥已配置 ✅"
else
    error "未输入公钥，跳过此步骤"
fi

# Step 3: 禁用 root SSH 登录 + 禁用密码登录
info "Step 3/6: 加固 SSH 配置..."

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 验证修改
grep -E "^PermitRootLogin|^PasswordAuthentication|^PubkeyAuthentication" /etc/ssh/sshd_config

warn "即将重启 SSH，请确保新用户能登录后再继续！"
read -p "已测试新用户登录？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    error "请先在新窗口测试 SSH 登录，再回来输入 yes"
    exit 1
fi

systemctl restart sshd
info "SSH 已重启 ✅"

# Step 4: 配置自动安全更新
info "Step 4/6: 配置自动安全更新..."
apt install unattended-upgrades -y > /dev/null 2>&1
dpkg-reconfigure -plow unattended-upgrades <<< "yes" > /dev/null 2>&1 || true
info "自动安全更新已启用 ✅"

# Step 5: 安装基础工具
info "Step 5/6: 安装基础工具..."
apt install -y curl wget git vim htop net-tools > /dev/null 2>&1
info "基础工具已安装 ✅"

# Step 6: 时区设置
info "Step 6/6: 设置时区..."
timedatectl set-timezone Asia/Shanghai
info "时区已设置为 Asia/Shanghai ✅"

echo ""
echo "======================================"
echo -e "${GREEN}  ✅ 加固完成！${NC}"
echo "======================================"
echo ""
echo "下次登录请使用："
echo "  ssh $NEW_USER@你的VPS_IP"
echo ""
echo "建议：保留当前 root SSH 会话，确认新用户能登录后再断开"
echo ""
