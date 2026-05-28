---
name: singbox-config
description: "Convert v2ray / clash subscriptions or URI lists into a complete Sing-box configuration. Use when the user asks to convert a v2ray subscription, clash config, or a list of node URIs (ss / ssr / vmess / vless / trojan / hysteria / hy2 / tuic / wireguard) into Sing-box JSON. 将 v2ray/clash 订阅或 URI 列表转换为 Sing-box 完整配置。"
allowed-tools:
  - Bash
  - Read
  - Write
---

# Generate Sing-box Configuration / 生成 Sing-box 配置

Convert v2ray / clash subscriptions or a list of proxy URIs into a complete Sing-box configuration file. Default output is a timestamped JSON, e.g. `sing-box-20260528-143052.json`.

将 v2ray/clash 订阅或 URI 转换为 Sing-box 完整配置。默认输出为带时间戳的配置文件。

**Privacy note / 隐私提示:** Subscription files contain node credentials. Never print the file's contents inline — only pass the path to `cli.js` via the `-i` flag.

订阅文件包含节点凭据。请勿直接读取/打印其内容，仅通过 `-i` 参数传递文件路径给 `cli.js`。

## Supported Protocols / 支持的协议

- Shadowsocks (ss)
- ShadowsocksR (ssr)
- VMess
- VLESS (including Reality / 包括 Reality)
- Trojan
- Hysteria / Hysteria2
- TUIC
- WireGuard

## Requirements / 环境要求

Either Node.js or Bun must be installed.

```bash
node --version   # detect Node.js
bun --version    # detect Bun (faster, optional)
```

Install if missing:

| Runtime | macOS | Windows |
|---------|-------|---------|
| Node.js | `brew install node` | `winget install OpenJS.NodeJS` |
| Bun | `brew install oven-sh/bun/bun` | `powershell -c "irm bun.sh/install.ps1 \| iex"` |

Or download from [Node.js](https://nodejs.org/) / [Bun](https://bun.sh/).

## Usage / 执行方法

Run from the skill directory:

```bash
cd .claude/skills/singbox-config

# Basic usage / 基本用法
node cli.js -i subscription.txt -o "sing-box-$(date +%Y%m%d-%H%M%S).json"

# Specific sing-box version / 指定版本
node cli.js -i subscription.txt -v 1.12 -o "sing-box-$(date +%Y%m%d-%H%M%S).json"

# With Bun (faster) / 使用 bun (更快)
bun cli.js -i subscription.txt -v 1.11 -o "sing-box-$(date +%Y%m%d-%H%M%S).json"
```

Always pass the subscription via `-i <path>` and output via `-o <path>` — do not pipe subscription contents through stdout.

## CLI Arguments / 命令行参数

| Flag | Description |
|------|-------------|
| `-v, --version` | Sing-box version (`1.11` or `1.12`, default `1.11`) |
| `-i, --input` | Input file path |
| `-o, --output` | Output file path |
| `-h, --help` | Print help |

## Input Formats / 输入格式

Three accepted forms:

1. Base64-encoded v2ray subscription
2. Multi-line URI list (one node per line)
3. Mixed format

## Output Features / 输出特性

- Nodes auto-grouped by region (HK / TW / JP / SG / US / 港 / 台 / 日 / 新 / 美)
- Includes full DNS and routing rules
- Clash API control panel enabled

## File Layout / 文件结构

```
singbox-config/
├── SKILL.md           # this skill
├── cli.js             # CLI entrypoint
├── test.js            # protocol parser core
├── 1.11/
│   ├── sing-box.js    # config builder
│   └── sing-box.json  # template
└── 1.12/
    ├── sing-box.js
    └── sing-box.json
```

## Credits / 致谢

This skill bundles a fork of the protocol parser used by community Sing-box converters. Upstream references:

- [wynemo/v2ray-to-sing-box](https://github.com/wynemo/v2ray-to-sing-box) — original v2ray-to-sing-box converter
- [SubStore](https://github.com/sub-store-org/Sub-Store) — protocol-conversion logic referenced in `test.js`
- Web demo: <https://singbox-to-uri.pages.dev/singbox_full_config>

## License

The skill metadata in this repository is MIT licensed. The bundled converter code retains its original upstream license — see the upstream projects above.
