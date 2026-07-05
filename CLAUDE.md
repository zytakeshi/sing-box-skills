# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**sing-box-skills** is a Claude Code skills package (`zytakeshi/sing-box-skills`) bundling skills for the [sing-box](https://github.com/SagerNet/sing-box) ecosystem. Skills are installed via `npx skills add zytakeshi/sing-box-skills`.

## Architecture

Each skill lives under `skills/<skill-name>/`. The two skills here are not symmetric in shape:

| Directory | Shape | Purpose |
|-----------|-------|---------|
| `skills/sing-box-builder/` | `SKILL.md` + `scripts/` + `references/` | Documentation-heavy build guide — no runtime code; `scripts/preflight.sh` validates environment, `references/` holds deep-dive notes |
| `skills/singbox-config/` | `SKILL.md` + `cli.js` + `test.js` + `1.11/` + `1.12/` | Runtime converter — `cli.js` is the entrypoint, version directories hold the Sing-box JSON templates per sing-box version |

## Skill Authoring Conventions

- **Frontmatter**: `name` (kebab-case), `description` (include all trigger phrases — this is how Claude matches user intent to skill). Multilingual descriptions are encouraged when the skill audience spans languages.
- **`SKILL.md`** is the canonical filename (uppercase). Older variants used lowercase `skill.md`; new skills should use `SKILL.md`.
- **Privacy-first**: `singbox-config` documents the rule that subscription contents must NOT be read inline by the LLM — only the file path is passed to `cli.js`. New skills handling sensitive input should mirror this pattern.
- **Pin upstream dependencies**: `sing-box-builder` deliberately documents *specific* Go versions, NDK r28, OpenJDK 17, and SagerNet's forked deps. Don't generalize away from concrete versions — they're the value.

## External Tool Dependencies

- `git`, `make`, `go` — `sing-box-builder`
- Android SDK + NDK r28, OpenJDK 17 — `sing-box-builder` for Android
- Xcode + macOS — `sing-box-builder` for Apple
- Docker — `sing-box-builder` for container builds
- Node.js or Bun — `singbox-config`

## Upstream / Attribution

`skills/singbox-config/test.js` and the converter bundles are forks of community projects (wynemo/v2ray-to-sing-box, SubStore). Preserve upstream attribution in any edits, and don't strip license headers from `cli.js`, `test.js`, or version-template files.

## Internationalization

README is maintained in three languages: `README.md` (English), `README.ja.md` (Japanese), `README.zh.md` (Chinese). Keep all three in sync when updating documentation.

## See Also

`admin-skills` (zytakeshi/admin-skills) is the sister repo with the broader sysadmin, PR, review, browser automation, live-research, and model-routing skills, including `/deploy`, `/commit-push`, `/create-pr`, `/codex`, `/codexloop`, `/codex-test`, `/ask-chatgpt-pro`, `/ask-grok`, `/cdp-chrome`, `/fleet-review`, `/team`, `/finish-translation`, `/html`, and `/fable5`.
