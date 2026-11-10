# 已知问题 / 踩坑记录

## 1. Shadowrocket 等非 Xray 客户端在 Xray 26.7.11+ 上连不上（有延迟、无流量）

### 现象
- 服务器配置能加载、端口在听、`tcp.ping.pe` 显示端口可达
- 客户端显示延迟（TCP 探测），但实际打不开网页
- 服务器日志出现：
  ```
  REALITY: processed invalid connection ... authentication failed or validation criteria not met
  ```
- 用 Xray 官方客户端（同参数）连接则正常

### 根因（两层）
1. **服务端**：Xray-core 从 commit [`af7eb68`](https://github.com/XTLS/Xray-core/commit/af7eb68028732a8ee3c0e5d6ab2b8a657bb2e770)（v26.7.11）起，
   REALITY 的 `minClientVer` 留空会自动变成 **`26.3.27`** 下限（以前留空=接受所有版本）。
   Shadowrocket / Mihomo / NekoBox 等非 Xray 客户端自报版本 < 26.3.27，
   REALITY 握手被静默转发到伪装站 → 表现为"有延迟但无流量"。
2. **客户端**：Shadowrocket 2.2.90 改了 TLS ClientHello 指纹实现，
   默认指纹不被新版 Xray 的 REALITY 接受。

### 修复
- **服务端**：REALITY 配置加 `"minClientVer": "1.0.0"`
  （本脚本已内置，见 `src/core.sh` 的 reality 生成段）
- **客户端**：Shadowrocket → 设置 → 全局 **TCP 指纹** → 选 **Chrome140**

### 为什么"别人的节点能用"
因为别人的服务器跑的是旧版 Xray（≤ v26.6.27），没有这个下限，也没有更严的指纹校验。

### 参考
- <https://github.com/XTLS/Xray-core/issues/6482>
- <https://github.com/MHSanaei/3x-ui/issues/5986>
- <https://xtls.github.io/config/transports/reality.html>
