# sing-box-skills

[English](README.md) | [日本語](README.ja.md) | **[中文](README.zh.md)**

---

[sing-box](https://github.com/SagerNet/sing-box) 生态的 Claude Code 技能集。从源码构建时不被 Go 版本不匹配、NDK 坑、链接器 flag 绊倒；一条命令把 v2ray / clash 订阅转成可用的 Sing-box 配置。

## 为什么用这些技能？

- **`/sing-box-builder`** — 从源码构建 sing-box 的 CLI 二进制、Android `.aar`、Apple `.xcframework` 或 Docker 镜像。处理 `GOTOOLCHAIN=local`、Go 1.23+ 的 `-checklinkname=0` 要求、SagerNet 维护的 fork 依赖、v1.13.0+ 必须的 Android/iOS 网络接口竞态修复，以及 App Store 提交所需的 Cronet 私有 Apple API 符号清理。
- **`/singbox-config`** — 把 v2ray / clash 订阅或节点 URI 列表（ss / ssr / vmess / vless / trojan / hysteria / hy2 / tuic / wireguard）转成完整的 Sing-box JSON 配置。自动按地区分组，自带 DNS + 路由规则、Clash API 面板。

## 安装

```bash
npx skills add zytakeshi/sing-box-skills
```

按需安装单个技能:

```bash
npx skills add zytakeshi/sing-box-skills@sing-box-builder
npx skills add zytakeshi/sing-box-skills@singbox-config
```

## 可用技能

| 技能 | 描述 |
|------|------|
| [sing-box-builder](skills/sing-box-builder/) | 从源码构建 sing-box — CLI / Android AAR / Apple xcframework / Docker。规避 Go 版本、linkname、NDK、Cronet 私有 API 的坑 |
| [singbox-config](skills/singbox-config/) | 把 v2ray / clash 订阅或 URI 列表转成完整的 Sing-box JSON 配置 |

## 使用方法

安装后，在 Claude Code 中:

- `/sing-box-builder` — 为目标平台构建 sing-box
- `/singbox-config -i subscription.txt -o config.json` — 转换订阅

## 致谢

`/singbox-config` 内置了社区 Sing-box 转换器使用的协议解析器的一份 fork。上游参考:

- [wynemo/v2ray-to-sing-box](https://github.com/wynemo/v2ray-to-sing-box)
- [SubStore](https://github.com/sub-store-org/Sub-Store)

`/sing-box-builder` 文档化了 [SagerNet/sing-box](https://github.com/SagerNet/sing-box) 的构建流程。

## 相关项目

- [admin-skills](https://github.com/zytakeshi/admin-skills) — 系统管理 / DevOps 技能集: `/deploy`、`/commit-push`、`/create-pr`、`/codex`、`/codexloop`、`/fleet-review`、`/team`、`/finish-translation`、`/html`
- [statusline4claudecode](https://github.com/zytakeshi/statusline4claudecode) — Claude Code 自定义状态栏

## 许可证

MIT — 见 [LICENSE](LICENSE)。`skills/singbox-config/` 下的转换器代码沿用其上游许可证；详见致谢章节。
