# Windows 用户完整操作指南

> 从"零基础"到"跑通第一个节点"的全流程
> 预计总耗时：45 分钟

---

## 准备工作清单

| 工具 | 用途 | 下载 |
|------|------|------|
| Chrome / Edge | 买 VPS、平时用 | 已装 |
| **Tabby** | SSH 连 VPS | https://tabby.sh/ |
| **Clash Verge Rev** | 代理客户端 | https://github.com/clash-verge-rev/clash-verge-rev/releases |
| 支付宝 | 充值 Vultr | 已装 |
| 邮箱 | 注册 Vultr | 已装 |

---

## 第一步：下载 Windows 工具（5 min）

### 1.1 下载 Tabby

1. 打开 https://tabby.sh/
2. 点 "Download"
3. 下载 Windows 安装包（Tabby-xxx.exe）
4. 双击安装 → 默认选项 → 完成

### 1.2 下载 Clash Verge Rev

1. 打开 GitHub Release 页：
   ```
   https://github.com/clash-verge-rev/clash-verge-rev/releases
   ```
2. 找到最新版（带 `Latest` 标签）
3. 下载 `xxx-windows-msvc-setup.exe`（安装版）
4. 双击安装 → 完成

**安装完先不启动**，等 VPS 买完再配。

---

## 第二步：买 Vultr VPS（10 min）

### 2.1 注册 + 充值

1. 浏览器打开 https://www.vultr.com/
2. 点 "Sign Up" → 用邮箱注册 → 验证邮箱
3. 登录后点左侧 **Billing** → **Make Payment**
4. 选 **Alipay** → 最低充值 **$10**（够用 2 个月）
5. 扫码支付完成

### 2.2 创建 SSH Key（关键步骤）

1. 左侧 **Products** → **SSH Keys**
2. 点 **Add New SSH Key**
3. 你会看到一段 PowerShell / CMD 命令（类似下面）：
   ```powershell
   ssh-keygen -t ed25519 -f $HOME/.ssh/id_ed25519 -N ""
   cat $HOME/.ssh/id_ed25519.pub | Set-Clipboard
   ```
4. **打开 PowerShell**（Win+R → 输入 `powershell` → 回车）
5. 粘贴上面的命令 → 回车
   - 提示 "Enter passphrase" → **直接回车跳过**（不设密码）
6. 命令会自动把公钥复制到剪贴板
7. 回到 Vultr SSH Keys 页面 → 在 "SSH Key" 输入框 **Ctrl+V 粘贴**公钥
8. **Name** 填个名字（如 `my-laptop`）→ 点 **Add SSH Key**

### 2.3 部署 VPS

1. 左侧 **Products** → **Deploy New Server**
2. 配置如下：

| 选项 | 选择 |
|------|------|
| **Location** | **Tokyo, Japan** ⭐ |
| **Image** | Ubuntu 22.04 LTS x64 |
| **Plan** | Cloud Compute · **1C 1GB 25GB SSD** · **$5/mo** |
| **Additional Features** | 全部**不勾选** |
| **SSH Key** | 勾选你刚才添加的 SSH Key |
| **Server Hostname** | 随便填（如 `vps-tokyo-01`） |

3. 点 **Deploy Now**
4. 等待 1-3 分钟 → 页面显示 IP 地址（如 `198.51.100.45`）
5. **记下这个 IP**（后面要用）

### 2.4 下载 .pem 私钥文件

1. Vultr 后台 → **Products** → 找到你刚创建的服务器
2. 点击服务器 → 找到 **SSH Key** 那一行
3. 旁边如果有下载图标，下载私钥文件
4. 保存到本地（如 `D:\vps-key\id_ed25519`）

⚠️ **不要把 .pem 文件提交到 GitHub**（已在 .gitignore 保护）

---

## 第三步：用 Tabby 连上 VPS（3 min）

### 3.1 配置连接

1. 打开 **Tabby**
2. 顶部菜单 → **Settings** → **Profiles & connections**
3. 点 **+ New profile** → 选 **SSH connection**
4. 填写：

| 字段 | 值 |
|------|-----|
| Name | `Vultr-Tokyo`（随便起名） |
| Host | `198.51.100.45`（你的 VPS IP） |
| User | `root` |
| Identity file | 选择你下载的 .pem 文件 |

5. 点 **Save**

### 3.2 测试连接

1. 双击刚保存的连接
2. 第一次会弹窗确认服务器指纹 → 点 **Accept**
3. 看到黑色窗口显示 `root@vultr:~#` = **连上了** ✅

⚠️ **常见问题**：
- 提示 "Permission denied" → 检查 .pem 文件路径、权限
- 提示 "Connection timed out" → 检查 IP 是否填错、是否被墙（用 `ping` 测试）

---

## 第四步：部署 Reality 节点（10 min）

**在 Tabby 的黑色窗口里**，依次粘贴以下命令（**右键粘贴**，不是 Ctrl+V）：

### 4.1 更新系统

```bash
apt update && apt upgrade -y
```

等待 1-2 分钟，看到 `Complete!` 表示完成。

### 4.2 启用 BBR + 防火墙

```bash
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p
ufw allow 22/tcp && ufw allow 443/tcp && ufw enable
```

看到 `Command may disrupt existing ssh connections` → 输入 `y` 回车。

### 4.3 一键部署 Reality

```bash
bash <(curl -Ls https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)
```

脚本会依次询问：

| 提示 | 输入 |
|------|------|
| 选择协议 | 输 `1`（VLESS-REALITY） |
| 端口 | 输 `443` |
| 伪装目标 | 输 `www.apple.com` |
| 其他 | **全部直接回车** |

跑完后脚本会输出：
- **节点链接**（`vless://...` 开头）→ 复制保存
- **二维码**（手机扫码用）
- **配置文件路径**（`/etc/sing-box/...`）

**成功标志**：看到类似输出
```
✅ 节点链接：vless://xxxxxx@198.51.100.45:443?...
✅ 二维码：https://api.qrserver.com/v1/create-qr-code/?data=vless://...
```

---

## 第五步：配置 Windows 代理客户端（5 min）

### 5.1 导入节点

1. 打开 **Clash Verge Rev**
2. 左侧 **Profiles** → 顶部 **+** → 选 **Import from clipboard**
3. 系统会自动读取刚才复制的 `vless://` 链接
4. 命名（如 `Vultr-Reality`）→ 点 **Save**

### 5.2 启用代理

1. 顶部 **Proxies** 标签
2. 选中刚导入的节点
3. 顶部 **System Proxy** 开关 → **打开**

---

## 第六步：验证（2 min）

打开浏览器访问：

| 测试 | 预期 | 状态 |
|------|------|------|
| https://openai.com | 能打开 | ✅ |
| https://www.google.com | 能打开 | ✅ |
| https://www.baidu.com | 秒开且不变慢 | ✅ |
| https://dnsleaktest.com | 显示国外 DNS | ✅ |

**全部 ✅ = 部署成功** 🎉

---

## 常见问题排查

### Q1: 跑脚本时报 "Permission denied"

**解决**：
```bash
chmod +x <脚本路径>
```

### Q2: 节点链接导入 Clash 后连不上

**排查**：
```bash
# 在 Tabby 窗口执行
systemctl status sing-box    # 检查服务是否运行
ss -tlnp | grep 443           # 检查端口是否监听
```

### Q3: 能上 Google 但不能上 ChatGPT

**原因**：IP 被 OpenAI 风控。
**解决**：销毁 VPS 重建（Vultr 后台 Destroy → Deploy New Server，IP 会换）。

### Q4: 速度很慢

**排查**：
```bash
# 检查 BBR
lsmod | grep bbr   # 有输出 = 启用成功

# 检查延迟
ping 8.8.8.8
```

---

## 下一步

- 📖 阅读 [03-维护与异常处理.md](03-维护与异常处理.md) 了解日常维护
- 📖 阅读 [04-AI研究基础设施指南.md](04-AI研究基础设施指南.md) 了解 GPT 科研 + 聚合 Dashboard
