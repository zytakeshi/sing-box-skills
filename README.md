# sing-box-skills

**[English](README.md)** | [日本語](README.ja.md) | [中文](README.zh.md)

---

Claude Code skills for the [sing-box](https://github.com/SagerNet/sing-box) ecosystem. Build it from source without tripping over Go version mismatches, NDK gotchas, or linker flags; convert v2ray / clash subscriptions to a working Sing-box config in one command.

## Why Use These Skills?

- **`/sing-box-builder`** — Build sing-box CLI binaries, Android `.aar`, Apple `.xcframework`, or Docker images from source. Handles `GOTOOLCHAIN=local`, the Go 1.23+ `-checklinkname=0` requirement, SagerNet's forked dependencies, the v1.13.0+ Android/iOS network-interface race fix, and the Cronet private-Apple-API scrub for App Store builds.
- **`/singbox-config`** — Convert v2ray / clash subscriptions or a list of node URIs (ss / ssr / vmess / vless / trojan / hysteria / hy2 / tuic / wireguard) to a complete Sing-box JSON config. Auto-grouped by region, DNS + routing rules included, Clash API panel enabled.

## Install

```bash
npx skills add zytakeshi/sing-box-skills
```

Or install a specific skill:

```bash
npx skills add zytakeshi/sing-box-skills@sing-box-builder
npx skills add zytakeshi/sing-box-skills@singbox-config
```

## Available Skills

| Skill | Description |
|-------|-------------|
| [sing-box-builder](skills/sing-box-builder/) | Build sing-box from source — CLI, Android AAR, Apple xcframework, Docker. Avoids Go-version, linkname, NDK, and Cronet private-API pitfalls |
| [singbox-config](skills/singbox-config/) | Convert v2ray / clash subscriptions or URI lists to a complete Sing-box JSON config |

## Usage

After installing, use the skills in Claude Code:

- `/sing-box-builder` — build sing-box for your target platform
- `/singbox-config -i subscription.txt -o config.json` — convert a subscription

## Credits

`/singbox-config` bundles a fork of the protocol parser used by community Sing-box converters. Upstream references:

- [wynemo/v2ray-to-sing-box](https://github.com/wynemo/v2ray-to-sing-box)
- [SubStore](https://github.com/sub-store-org/Sub-Store)

`/sing-box-builder` documents the build pipeline for [SagerNet/sing-box](https://github.com/SagerNet/sing-box).

## See Also

- [admin-skills](https://github.com/zytakeshi/admin-skills) — Sysadmin, PR, review, browser automation, live-research, and model-routing skills including `/deploy`, `/create-pr`, `/codex`, `/codex-test`, `/ask-chatgpt-pro`, `/ask-grok`, `/cdp-chrome`, `/fleet-review`, `/team`, `/finish-translation`, `/html`, and `/fable5`
- [statusline4claudecode](https://github.com/zytakeshi/statusline4claudecode) — A custom status line for Claude Code

## License

MIT — see [LICENSE](LICENSE). The bundled converter code in `skills/singbox-config/` retains its original upstream license; see the upstream projects in the Credits section.
