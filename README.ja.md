# sing-box-skills

[English](README.md) | **[日本語](README.ja.md)** | [中文](README.zh.md)

---

[sing-box](https://github.com/SagerNet/sing-box) エコシステム向け Claude Code スキル集。Go のバージョン不一致、NDK の落とし穴、リンカフラグでハマらずにソースからビルドし、v2ray / clash 購読を一発で Sing-box 設定に変換します。

## このスキルを使うメリット

- **`/sing-box-builder`** — sing-box の CLI バイナリ、Android `.aar`、Apple `.xcframework`、Docker イメージをソースからビルド。`GOTOOLCHAIN=local`、Go 1.23+ の `-checklinkname=0` 要件、SagerNet のフォーク依存、v1.13.0+ で必須の Android/iOS ネットワークインタフェース競合パッチ、App Store 提出用 Cronet 非公開 Apple API シンボルの除去 — すべて面倒見ます。
- **`/singbox-config`** — v2ray / clash 購読またはノード URI 一覧（ss / ssr / vmess / vless / trojan / hysteria / hy2 / tuic / wireguard）を完全な Sing-box JSON 設定に変換。地域別自動グループ化、DNS とルーティングルール込み、Clash API パネル有効。

## インストール

```bash
npx skills add zytakeshi/sing-box-skills
```

特定のスキルのみ:

```bash
npx skills add zytakeshi/sing-box-skills@sing-box-builder
npx skills add zytakeshi/sing-box-skills@singbox-config
```

## 利用可能なスキル

| スキル | 説明 |
|--------|------|
| [sing-box-builder](skills/sing-box-builder/) | sing-box をソースからビルド — CLI / Android AAR / Apple xcframework / Docker。Go バージョン・linkname・NDK・Cronet 非公開 API の落とし穴を回避 |
| [singbox-config](skills/singbox-config/) | v2ray / clash 購読または URI リストを完全な Sing-box JSON 設定に変換 |

## 使い方

インストール後、Claude Code で:

- `/sing-box-builder` — 対象プラットフォーム向けに sing-box をビルド
- `/singbox-config -i subscription.txt -o config.json` — 購読を変換

## クレジット

`/singbox-config` はコミュニティの Sing-box 変換ツールが使うプロトコルパーサのフォークを同梱しています。上流参照:

- [wynemo/v2ray-to-sing-box](https://github.com/wynemo/v2ray-to-sing-box)
- [SubStore](https://github.com/sub-store-org/Sub-Store)

`/sing-box-builder` は [SagerNet/sing-box](https://github.com/SagerNet/sing-box) のビルドパイプラインを文書化しています。

## 関連プロジェクト

- [admin-skills](https://github.com/zytakeshi/admin-skills) — システム管理、PR、レビュー、ブラウザ自動化、ライブ調査、モデルルーティング用スキル集。`/deploy`、`/create-pr`、`/codex`、`/codex-test`、`/ask-chatgpt-pro`、`/ask-grok`、`/cdp-chrome`、`/fleet-review`、`/team`、`/finish-translation`、`/html`、`/fable5` など
- [statusline4claudecode](https://github.com/zytakeshi/statusline4claudecode) — Claude Code 用カスタムステータスライン

## ライセンス

MIT — [LICENSE](LICENSE) を参照。`skills/singbox-config/` 配下の変換コードは上流のライセンスを継承します（クレジットセクション参照）。
