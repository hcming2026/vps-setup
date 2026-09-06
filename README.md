# VPS 自建科学上网 + AI 科研基础设施

> 个人 / 科研用户自建 VLESS+Reality 节点的完整工程化方案
> 配套工具链：Vultr · sing-box · Tabby · Clash Verge Rev
> 最后更新：2026-09

---

## 🎯 这个仓库是什么

一个**可复现、可维护、可演进**的自建 VPS 科学上网项目骨架。包含：

- 方案选型与思路文档
- Windows 用户的完整操作指南
- 部署脚本（服务端加固 + Reality 节点）
- 配置文件模板（sing-box + Clash Verge Rev）
- 维护与异常处理 SOP

**适用人群**：科研用户 / 研究生 / 教师 / 进阶个人用户，需要稳定访问 OpenAI / Google Scholar / GitHub 等境外资源。

---

## 📁 目录结构

```
vps-setup/
├── README.md                       ← 你正在看
├── .gitignore                      ← 保护 .pem / .key 等敏感文件
├── docs/                           ← 所有文档
│   ├── 01-方案选择与思路.md        ← 思路梳理 + 选型对比
│   ├── 02-Windows操作指南.md       ← Windows 用户完整 6 步走
│   ├── 03-维护与异常处理.md        ← 日常维护 + 异常处理预案
│   └── 04-AI研究基础设施指南.md    ← 主指南（GPT 科研 + 聚合 Dashboard）
├── scripts/                        ← 部署脚本
│   ├── deploy-reality.sh           ← VPS 一键部署（BBR + 防火墙 + Reality）
│   ├── harden-server.sh            ← 服务器基础加固
│   └── backup-config.sh            ← 配置自动备份
└── configs/                        ← 配置模板
    ├── sing-box-server.json        ← sing-box 服务端配置
    └── clash-verge.yaml            ← Clash Verge Rev 客户端配置
```

---

## 🚀 30 分钟快速开始

### 前置条件

| 项 | 要求 |
|----|------|
| 操作系统 | Windows 10/11 |
| 浏览器 | Chrome / Edge |
| 支付宝 | 用于充值 Vultr（最低 $10） |
| 邮箱 | 用于注册 Vultr 账号 |

### 5 步上手

1. **下载 Windows 工具**（5 min）
   - [Tabby](https://tabby.sh/)：SSH 客户端
   - [Clash Verge Rev](https://github.com/clash-verge-rev/clash-verge-rev/releases)：代理客户端

2. **买 VPS**（10 min）
   - 打开 https://www.vultr.com/
   - Tokyo 机房 / 1C1G / Ubuntu 22.04 / $5/月
   - **必须用 SSH Key 登录**（不要密码）

3. **用 Tabby 连 VPS**（3 min）
   - 填 IP + 用户名 `root` + 选 .pem 私钥

4. **跑部署脚本**（10 min）
   ```bash
   curl -fsSL https://raw.githubusercontent.com/你的用户名/vps-setup/main/scripts/deploy-reality.sh -o deploy.sh
   chmod +x deploy.sh
   ./deploy.sh
   ```

5. **导入 Clash 配置 + 验证**（2 min）
   - 粘贴节点链接 → 启用系统代理
   - 访问 https://openai.com → 能开 = 成功

📖 详细图文指引：[docs/02-Windows操作指南.md](docs/02-Windows操作指南.md)

---

## 🧰 技术栈选型

| 组件 | 选择 | 理由 |
|------|------|------|
| VPS 商家 | Vultr | 按小时计费，IP 不好随时销毁重建 |
| 机房 | Tokyo | 回国线路稳定，延迟低 |
| 操作系统 | Ubuntu 22.04 LTS | 主流、生态完善 |
| 代理核心 | sing-box | 2026 年事实标准，多协议支持 |
| 协议 | VLESS+Reality | 当前唯一长期稳定的抗检测方案 |
| SSH 客户端 | Tabby | 跨平台、免费、界面现代 |
| 代理客户端 | Clash Verge Rev | 全平台、易用、规则丰富 |
| 配置同步 | GitHub 私有仓 | 多设备零成本同步 |

📖 选型对比详情：[docs/01-方案选择与思路.md](docs/01-方案选择与思路.md)

---

## 📊 月度成本估算

| 项 | 月费 |
|----|------|
| VPS（Vultr 1C1G）| $5 ≈ ¥36 |
| 域名（可选）| $1 ≈ ¥7 |
| 国内模型 API（按用量）| ¥10-100 |
| **合计** | **约 ¥50-150/月** |

GPT Pro 订阅另算（$20-200/月，按使用强度选）。

---

## 🛡️ 安全清单

部署前必须确认：

- [ ] VPS 用 SSH Key 登录（**禁用密码**）
- [ ] 禁用 root 远程登录
- [ ] 启用防火墙 ufw（仅开放 22 + 443）
- [ ] 启用 BBR 拥塞控制
- [ ] 安装 fail2ban 防 SSH 爆破
- [ ] 配置自动安全更新
- [ ] Clash Verge 启用 DNS 防泄漏（fake-ip）

---

## 🔄 演进路线

```
阶段 1（Week 1）   单 Reality 节点 + Clash Verge
       ↓ IP 被封经验
阶段 2（Month 2）  增加 Hysteria2 备用协议
       ↓ 想加 CDN
阶段 3（Month 3+） Cloudflare CDN + 多 VPS 备份
       ↓ 流量上来
阶段 4（半年后）   多协议 + 多机房 + 自动化运维
```

---

## 📚 文档索引

- 📘 [docs/01-方案选择与思路.md](docs/01-方案选择与思路.md) — 思路梳理与选型对比
- 📗 [docs/02-Windows操作指南.md](docs/02-Windows操作指南.md) — Windows 完整操作流程
- 📕 [docs/03-维护与异常处理.md](docs/03-维护与异常处理.md) — 日常维护 + 异常处理
- 📙 [docs/04-AI研究基础设施指南.md](docs/04-AI研究基础设施指南.md) — GPT 科研 + 聚合 Dashboard

---

## ⚠️ 合规声明

本项目仅供技术学习与科研用途。请遵守所在单位 / 学校的 IT 政策以及所在地区的法律法规。敏感数据请使用国内模型渠道，避免数据出境风险。

---

## 📜 许可证

个人项目，仅供本人使用。如需分享给他人，请评估合规风险。
