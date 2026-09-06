# VLESS+Reality 深度解析

> 为什么 2026 年必须用 Reality？它到底怎么抗检测？
> 适用人群：想深入理解原理的进阶用户

---

## 一、问题背景：GFW 是怎么识别代理的？

要理解 Reality 的价值，先看传统代理是怎么被识别的。

### 1.1 传统代理的特征（容易识别）

| 协议 | 特征 | 为什么容易被识别 |
|------|------|------------------|
| **VMess** | 固定 UUID + alterId 握手 | UUID 是 32 字节标准格式，GFW 可统计 |
| **Shadowsocks** | 固定密码 + 加密流量 | 加密后流量"无意义"特征明显 |
| **Trojan** | HTTPS + 证书 + 密码 | 真实站点不会有这种流量模式 |
| **VLESS（无 Reality）** | 裸 VLESS 协议 | 没有 TLS 包装，特征明显 |

**GFW 的检测策略**：
- 主动探测：向可疑 IP 发送特定 payload，看响应是否符合代理特征
- 被动分析：长期观察流量模式，发现异常
- 机器学习：基于已识别样本训练模型

### 1.2 为什么 VLESS+Reality 抗检测？

Reality 不像传统代理那样"主动应答"。它**伪装成目标 TLS 服务器**，让 GFW 看到的就像普通 HTTPS 访问。

---

## 二、Reality 的工作原理

### 2.1 核心思想

**Reality 不生成 TLS 握手，而是"借用"真实网站的 TLS Server Hello**。

```
普通 HTTPS（合法网站）：
  Client → 你好，我要访问 www.apple.com:443
  Server → 这是我的 TLS 证书（合法的 Apple 证书）

Reality 代理：
  Client → 你好，我要访问 www.apple.com:443（伪装）
  Server → 不响应/不可达
  Real Proxy → 主动"插话"：用自己生成的伪证书应答
  Client → 不知道对面其实是代理，继续加密通信
```

**关键**：GFW 看到的是"访问 www.apple.com 的 TLS 1.3 握手"，跟普通访问一模一样。

### 2.2 TLS 1.3 的握手机制（为什么 Reality 走得通）

TLS 1.3 引入了 0-RTT（零往返）和简化的握手流程：

```
Client                              Reality Server
  │                                       │
  │──── ClientHello ────────────────────→│ (1) 客户端发起握手
  │                                       │ (2) 服务器检测 ClientHello
  │                                       │     - 如果是真实 Apple 流量 → 转给 dest
  │                                       │     - 如果是 Reality 客户端 → 自己应答
  │←──── ServerHello ──────────────────│ (3) Reality 用伪证书应答
  │←──── EncryptedExtensions ──────────│
  │←──── Certificate (伪证书) ───────│
  │←──── CertificateVerify ───────────│
  │←──── Finished ────────────────────│
  │                                       │
  │──── Finished ────────────────────→│ (4) 握手完成
  │                                       │
  │──── 应用数据（加密）──────────────→│ (5) 正常加密通信
```

**对 GFW 来说**：第 (3) 步看到的 ServerHello 跟真实 Apple 服务器的 ServerHello **无法区分**。

### 2.3 Reality 的"dest" 机制

`dest`（destination）是 Reality 配置的关键参数：

```json
{
  "reality": {
    "handshake": {
      "server": "www.apple.com",    // 伪装目标
      "server_port": 443             // 端口
    }
  }
}
```

**作用**：
- 真实客户端访问时 → Reality 把请求**转给** www.apple.com（看起来正常）
- Reality 客户端访问时 → Reality 自己处理（提供代理）

**GFW 的探测困境**：
- 主动探测：用普通浏览器访问 → 看起来就是访问 apple.com
- 主动探测：用 Reality 特征 payload → Reality 不应答，GFW 收到"无响应"
- **无法区分**：GFW 不能直接判断这是代理还是真实网站

---

## 三、关键技术细节

### 3.1 关键参数解析

```json
{
  "private_key": "你的REALITY私钥",     // 服务器私钥
  "short_id": ["你的短ID"],              // 客户端验证用
  "dest": "www.apple.com:443",          // 伪装目标
  "server_names": ["www.apple.com"]      // 允许的 SNI
}
```

**private_key**：
- 服务器用私钥签名，证明自己是 Reality
- 客户端用对应的公钥验证
- 32 字节，Base64 编码

**short_id**：
- 16 位以内的随机字符串
- 客户端发送时附带，服务器验证
- 增加一层认证，防止被探测

**server_names**：
- 允许客户端使用的 SNI 列表
- 通常填伪装目标的域名

### 3.2 抗量子计算（2026 年新特性）

Reality 在 2024 年升级为 X25519 + Kyber 混合加密：

```
传统：仅 X25519（椭圆曲线）
Reality v2：X25519 + Kyber-768（后量子算法）
```

**意义**：即便未来量子计算机能破解 X25519，Kyber 也保平安。

### 3.3 uTLS 指纹伪装

Reality 配套使用 **uTLS**（Go 实现的 TLS 库）：

```
普通代理客户端：
  TLS ClientHello 指纹：Go HTTP 客户端的特征（与 Chrome 不一致）

Reality + uTLS：
  TLS ClientHello 指纹：伪装成 Chrome 120 / Firefox 120
```

**为什么重要**：GFW 可以基于 TLS 客户端指纹判断"这是不是真实浏览器"。Reality 自动伪装成主流浏览器。

---

## 四、部署 Reality 的核心步骤

### 4.1 生成密钥对

```bash
# sing-box 生成 Reality 密钥对
sing-box generate reality-keypair

# 输出示例：
# PrivateKey: u8B_v5Z3MjA3hLp2kRqXwN4dG5fK7jM8nP9qS0tU1v=
# PublicKey:  Z5X_wV3uT2sR1qP0nM9kJ8hG7fD6sA5pB4nC3mE2lK=
```

### 4.2 选择伪装目标

**好的伪装目标**：
- ✅ 大型 CDN：`www.apple.com`、`www.microsoft.com`
- ✅ 大型云服务：`www.cloudflare.com`
- ✅ 流量大、SNI 常见：选热门的 HTTPS 站点
- ✅ 支持 TLS 1.3、HTTP/2

**避免**：
- ❌ 小众网站（流量特征异常）
- ❌ 不支持 TLS 1.3 的老站点
- ❌ 中国屏蔽的网站（GFW 一看就不正常）

**测试伪装目标**：
```bash
# 检查目标是否支持 TLS 1.3
echo | openssl s_client -connect www.apple.com:443 -tls1_3 2>/dev/null | grep "Protocol"
```

### 4.3 完整 sing-box 配置（最小可用）

```json
{
  "log": { "level": "info" },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-in",
      "listen": "::",
      "listen_port": 443,
      "users": [
        {
          "uuid": "你的UUID",
          "flow": "xtls-rprx-vision"
        }
      ],
      "tls": {
        "enabled": true,
        "server_name": "www.apple.com",
        "reality": {
          "enabled": true,
          "handshake": {
            "server": "www.apple.com",
            "server_port": 443
          },
          "private_key": "你的私钥",
          "short_id": ["你的短ID"]
        }
      }
    }
  ],
  "outbounds": [
    { "type": "direct", "tag": "direct" }
  ]
}
```

---

## 五、客户端连接过程（用户视角）

### 5.1 客户端发起请求

```
1. Clash Verge Rev 看到你要访问 openai.com
2. Clash 找到 vless 节点 → 加密你的请求
3. Clash 向 VPS:443 发送 TLS ClientHello
4. ClientHello 里的 SNI 写 "www.apple.com"
5. Reality 看到这个 ClientHello → 自己应答
6. TLS 握手完成（伪装成访问 apple.com）
7. 加密的代理请求开始传输
```

### 5.2 GFW 看到的

```
普通 HTTPS 请求 → www.apple.com:443 (TLS 1.3)
```

**没有任何代理特征**，跟真的访问 apple.com 一模一样。

---

## 六、Reality vs 其他"抗审查"方案对比

| 方案 | 抗检测 | 速度 | 配置复杂度 | 适用场景 |
|------|--------|------|----------|---------|
| **VLESS+Reality** | ★★★★★ | 中-高 | 中 | **主力方案**（长期稳定）|
| Hysteria 2 | ★★★★ | 极高（QUIC）| 中 | 备用协议（大流量加速）|
| Shadowsocks-2022 | ★★★ | 高 | 低 | 兜底 |
| Trojan | ★★★ | 中 | 中 | 旧客户端兼容 |
| VMess | ★★ | 中 | 高 | ❌ 不建议新建 |

---

## 七、Reality 的局限

**它不是万能的**：

| 局限 | 说明 |
|------|------|
| **不能防御主动探测 + 关联分析** | 如果 GFW 知道你的 IP，且发现"从该 IP 同时访问了多个不可解释的目的地"，仍可关联 |
| **依赖伪装目标** | 如果伪装目标网站改版或下线，需要更换 |
| **TCP-only** | 默认只走 TCP，不适合 UDP 场景（游戏、视频）|
| **不适合大规模分发** | 单节点用户多了易被关联 |

**Reality 的"抗检测"是相对的**——它的目标是"让 GFW 看到的是普通 HTTPS 流量"，而不是"绝对无法识别"。

---

## 八、进阶玩法

### 8.1 多 Reality 节点

```json
"inbounds": [
  { "listen_port": 443, "tag": "node-jp", ... },
  { "listen_port": 8443, "tag": "node-sg", ... }
]
```

不同端口对应不同节点，避免单节点故障。

### 8.2 Reality + Hysteria2 双协议

```json
"inbounds": [
  { "type": "vless", "tag": "reality", ... },
  { "type": "hysteria2", "tag": "hy2", ... }
]
```

TCP 用 Reality，UDP/QUIC 用 Hysteria2，互为备份。

### 8.3 CDN 兜底（VLESS+WS+TLS+CF）

如果 IP 被墙，套 Cloudflare CDN：
- 流量特征：Cloudflare CDN 的 TLS 握手
- 缺点：性能损失 10-30%

---

## 九、调试 Reality 问题

### 9.1 服务端日志

```bash
journalctl -u sing-box -f
```

看到 `accepted` = 连接成功；看到 `rejected` = 配置错误。

### 9.2 客户端日志

Clash Verge → Logs → 看到 `dial ... connection succeeded` = 成功。

### 9.3 网络连通性

```bash
# 从你的 Windows 电脑
curl --tlsv1.3 --tls-max 1.3 https://www.apple.com -I
```

如果能拿到 HTTP 200，说明 TLS 1.3 握手通畅。

### 9.4 抓包分析

```bash
# 在 VPS 上抓包（看流量特征）
tcpdump -i any -nn port 443 -c 100
```

应该看到标准的 TLS 1.3 握手包。

---

## 十、参考资料

- [Xray VLESS 文档](https://xtls.github.io/en/config/inbounds/vless.html)
- [sing-box Reality 配置](https://sing-box.sagernet.org/configuration/inbound/vless/#reality)
- [Reality 协议论文](https://github.com/XTLS/REALITY)
- [uTLS 指纹库](https://github.com/refraction-networking/utls)

---

**一句话总结**：Reality 不是"加密"更强，而是"看起来更普通"。它通过伪装成主流 TLS 站点，让 GFW 无法在协议层识别代理流量。
