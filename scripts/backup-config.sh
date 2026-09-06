#!/bin/bash
#
# backup-config.sh
# 自动备份 sing-box 配置到本地 + （可选）上传到云端
#
# 使用方法：
#   1. 修改下面的 BACKUP_DIR 为你的本地备份目录
#   2. 添加到 crontab：0 3 * * * /root/scripts/backup-config.sh
#

set -e

# 配置
BACKUP_DIR="/root/backups/sing-box"
SING_BOX_CONFIG="/etc/sing-box/config.json"
KEEP_DAYS=30  # 保留最近 30 天的备份

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 生成时间戳
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/config_${TIMESTAMP}.json"

# 备份配置
if [ -f "$SING_BOX_CONFIG" ]; then
    cp "$SING_BOX_CONFIG" "$BACKUP_FILE"
    echo "[$(date)] ✅ 备份成功: $BACKUP_FILE"

    # 清理 30 天前的备份
    find "$BACKUP_DIR" -name "config_*.json" -mtime +$KEEP_DAYS -delete
    echo "[$(date)] 已清理 $KEEP_DAYS 天前的旧备份"

    # 显示当前备份列表
    echo ""
    echo "当前备份列表："
    ls -lh "$BACKUP_DIR" | grep "config_"
else
    echo "[$(date)] ❌ 配置文件不存在: $SING_BOX_CONFIG"
    exit 1
fi

# 可选：上传到云端（取消注释并配置）
# 如果用 SCP 上传到本地电脑：
# scp "$BACKUP_FILE" user@your_local_ip:/path/to/backup/

# 如果用 rsync 同步到云盘：
# rsync -avz "$BACKUP_DIR/" /mnt/cloud-drive/sing-box-backup/

# 如果用 rclone 上传到 Google Drive / OneDrive：
# rclone copy "$BACKUP_FILE" remote:backups/sing-box/

echo ""
echo "[$(date)] 备份任务完成"
