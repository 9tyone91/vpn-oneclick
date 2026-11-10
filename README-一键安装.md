# 一键安装脚本（双内核可选）

一份脚本，安装时选内核：**v2ray-core** 或 **xray-core**。

## 一、包结构

```
vpn-oneclick/
├── install.sh        # 统一安装器（关键：选择内核 + 装对应内核和脚本）
├── v2ray.sh          # v2ray 入口（装 v2ray 时用）
├── xray.sh           # xray 入口（装 xray 时用）
└── src/              # 共享脚本逻辑（core-aware）
    ├── init.sh       # 按 is_core 决定内核名/仓库/路径
    ├── core.sh       # REALITY 仅在 xray 内核时启用
    └── ...
```

## 二、安装方式

### 1) 交互选择（推荐给最终用户）
```bash
bash <(curl -fsSL https://你的域名/install.sh)
```
运行后会问：
```
请选择要安装的内核:
  1) v2ray-core   经典, 通用, 兼容性好
  2) xray-core    支持 REALITY / XTLS, 抗检测更强 (推荐)
请输入 [1-2]:
```

### 2) 指定内核（适合批量/自动化）
```bash
bash <(curl -fsSL https://你的域名/install.sh) -c xray     # 装 Xray
bash <(curl -fsSL https://你的域名/install.sh) -c v2ray    # 装 v2ray
```

### 3) 本地安装（把整个目录传上去）
```bash
cd vpn-oneclick
bash install.sh -l -c xray     # 本地 + 指定内核
bash install.sh -l            # 本地 + 交互选内核
```

## 三、安装时怎么选内核（原理）

`install.sh` 里 `main()` 的顺序是：
```
pass_args  →  choose_core  →  set_core_vars  →  检查已装  →  下载安装
```
- `pass_args` 解析 `-c v2ray|xray`，存到 `core_choice`
- 没给 `-c` 就 `choose_core` 弹菜单（读 `/dev/tty`，兼容 `curl | bash`）
- `set_core_vars` 根据选择设置：
  | core_choice | is_core | 仓库 | 入口 | 路径 |
  |---|---|---|---|---|
  | xray | xray | xtls/xray-core | xray.sh | /etc/xray |
  | v2ray | v2ray | v2fly/v2ray-core | v2ray.sh | /etc/v2ray |

## 四、安装后

- 装 xray → 命令 `xray`，路径 `/etc/xray`，菜单里含 `VLESS-XTLS-uTLS-REALITY`
- 装 v2ray → 命令 `v2ray`，路径 `/etc/v2ray`，菜单里**不含** REALITY（选择逻辑自动过滤）
- 若在 v2ray 内核下强用 `add r`，会提示：`REALITY 仅支持 Xray 内核`

## 五、分发注意

网络安装时，`install.sh` 会从 `233boy/v2ray` 或 `233boy/xray` 的 release 拉 `code.zip`（**官方原版，不是你的改版**）。
要分发你的二开版，二选一：

1. **用本地安装**：把 `vpn-oneclick/` 整个目录上传，`bash install.sh -l -c xray`
2. **自建 release**：把 `install.sh + v2ray.sh + xray.sh + src/` 打成 `code.zip`，改 `install.sh` 里
   `is_sh_repo=$author/$is_core` 指向你的仓库，托管后即可 `bash <(curl ...)`

## 六、已验证

- 全部 13 个脚本 `bash -n` 通过
- `set_core_vars` 两内核变量正确（xray→xtls/xray-core，v2ray→v2fly/v2ray-core）
- 协议过滤：v2ray 17 项无 REALITY；xray 18 项含 REALITY（第 10 位）
- `-c XRAY` 大小写归一、非法值拒绝

---

## 七、改成你的（已应用）

- 作者：`author=9tyone91`（菜单标题会显示 `by 9tyone91`）
- 分发仓库：`is_sh_repo=9tyone91/vpn-oneclick`
- about 页：Github → `https://github.com/9tyone91`，脚本仓库 → `https://github.com/9tyone91/vpn-oneclick`
- 主菜单底部链接：改为 `https://github.com/9tyone91`
- 分享链接 remark（`#9tyone91-...`）已替换

> 若仓库名不是 `vpn-oneclick`，改两处：`install.sh` 的 `set_core_vars()` 与 `src/init.sh` 里的
> `is_sh_repo=9tyone91/<你的仓库名>`。

## 八、发布步骤（用它做一键命令）

1. 在 GitHub 建仓库：`9tyone91/vpn-oneclick`
2. 上传 `install.sh`（仓库根目录即可）
3. 新建 Release，把 `code.zip` 作为附件上传
4. 一键命令：

```bash
# 交互选择内核
bash <(curl -fsSL https://raw.githubusercontent.com/9tyone91/vpn-oneclick/main/install.sh)

# 直接指定
bash <(curl -fsSL https://raw.githubusercontent.com/9tyone91/vpn-oneclick/main/install.sh) -c xray
```

`install.sh` 会从
`https://github.com/9tyone91/vpn-oneclick/releases/latest/download/code.zip`
拉你的二开版脚本，再按选择装 Xray 或 v2ray 内核。

### 校验 code.zip
```bash
unzip -l code.zip   # 应含 v2ray.sh xray.sh src/
```
