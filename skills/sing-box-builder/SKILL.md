---
name: sing-box-builder
description: "This skill provides comprehensive guidance for building sing-box from source, covering Go version requirements, build tags, linker flags, CGO/NDK setup, mobile library builds, and troubleshooting common failures. This skill should be used when the user wants to build sing-box CLI binaries, Android AAR libraries, Apple xcframeworks, or Docker images from the sing-box source repository. It prevents common pitfalls like Go version mismatches, missing linker flags, and dependency conflicts."
---

# sing-box Source Builder

Build sing-box binaries, mobile libraries, and Docker images from source without running into Go version mismatches, linkname errors, or dependency conflicts.

## When to Use

- Building sing-box CLI binary from source
- Building Android `.aar` mobile library (libbox)
- Building Apple `.xcframework` mobile library (Libbox)
- Building Docker images for sing-box
- Troubleshooting sing-box build failures
- Cross-compiling sing-box for different platforms

## Critical Knowledge

### GOTOOLCHAIN=local

The Makefile sets `export GOTOOLCHAIN=local` on every build target. This **disables Go's automatic toolchain downloading**. The exact Go version installed on the machine is used. If the installed version does not meet the minimum, the build fails immediately:

```
go: go.mod requires go >= 1.23.1 (running go 1.22.x; GOTOOLCHAIN=local)
```

**Always verify Go version before building.** Do NOT attempt to override `GOTOOLCHAIN`.

### Go Version Requirements

Check `go.mod` in the repo for the current minimum. As of known versions:

| sing-box branch / version | Minimum Go | CI Production Go |
|---|---|---|
| 1.13.x | Go 1.24.7 | Go 1.26.1 |
| 1.12.x | Go 1.23.1 | Go 1.25.8 |
| 1.11.x | Go 1.23.1 | Go 1.25.3 |
| 1.10.x | Go 1.20.0 | - |
| 1.9.x | Go 1.18.5 (Go 1.20+ with `with_quic`/`with_utls`) | - |
| dev-next / main-next | Check `go.mod` | Check `.github/workflows/build.yml` |

**Before building, always run:**
```bash
head -5 go.mod  # Check minimum Go version
go version       # Verify installed Go version
```

### Required Linker Flags (Go 1.23+)

sing-box uses `//go:linkname` to access internal stdlib functions. Go 1.23+ blocks this by default. **Always pass these linker flags for production builds:**

```bash
-ldflags "-checklinkname=0 -X 'github.com/sagernet/sing-box/constant.Version=VERSION' -X 'internal/godebug.defaultGODEBUG=multipathtcp=0' -s -w -buildid="
```

| Flag | Purpose |
|---|---|
| `-checklinkname=0` | Disables Go 1.23+ linkname restriction enforcement |
| `-X '...Version=...'` | Injects version string |
| `-X '...multipathtcp=0'` | Disables Go 1.24+ default Multipath TCP on listeners (sing-box has its own MPTCP control via `tcp_multi_path` option) |
| `-s -w` | Strip debug info and DWARF |
| `-buildid=` | Strip build ID for reproducibility |

Some versions ship `release/LDFLAGS` and `release/DEFAULT_BUILD_TAGS*` reference files — check if they exist before relying on them.

### SagerNet Forked Dependencies (DO NOT SUBSTITUTE)

sing-box depends on SagerNet-maintained forks of standard Go libraries. **Never** substitute upstream versions. **Never** run `go get` to update individual forked dependencies.

| Dependency | Fork Of | Why |
|---|---|---|
| `github.com/sagernet/gomobile` | `golang.org/x/mobile` | Custom mobile build features |
| `github.com/sagernet/quic-go` | `github.com/quic-go/quic-go` | sing-box modifications |
| `github.com/sagernet/gvisor` | `gvisor.dev/gvisor` | Custom network stack |
| `github.com/sagernet/wireguard-go` | `golang.zx2c4.com/wireguard` | Custom WireGuard impl |
| `github.com/sagernet/tailscale` | `github.com/tailscale/tailscale` | sing-box specific mods |
| `github.com/metacubex/utls` | `github.com/refraction-networking/utls` | MetaCubeX uTLS fork |

**If dependencies break:** Run `go mod tidy` only. Never manually update individual forked packages.

## CRITICAL: Android/iOS Network Interface Race Condition Fix (v1.13.0+)

### The Problem

sing-box v1.13.0+ uses gRPC-based `CommandServer.StartOrReloadService()` instead of the old `NewService().Start()`. On Android and iOS, remote rule-set downloads during startup fail with:

```
failed to create session: no available network interface
```

### Root Cause

During `box.Start()`, the startup sequence is:
1. `NetworkManager.Start(Initialize)` — starts the platform interface monitor (async callback via gomobile)
2. `Router.Start(Start)` — immediately tries to download remote rule sets

On Android, the `DefaultNetworkMonitor` **defers** the initial interface callback via `Handler.post()` to avoid JNI re-entrancy. This means `NetworkManager.NetworkInterfaces()` returns an empty slice when rule sets try to download, causing "no available network interface".

### The Fix

In `route/network.go`, add a synchronous `UpdateInterfaces()` call immediately after the interface monitor starts, inside the `StartStateInitialize` case:

```go
if r.interfaceMonitor != nil {
    monitor.Start("initialize interface monitor")
    err := r.interfaceMonitor.Start()
    monitor.Finish()
    if err != nil {
        return err
    }
}
// ADD THIS: Pre-populate network interfaces synchronously
if err := r.UpdateInterfaces(); err != nil {
    r.logger.Warn("pre-populate network interfaces: ", err)
}
```

This calls `platformInterface.NetworkInterfaces()` (which is synchronous via gomobile) to populate the interface list before rule sets attempt to download, eliminating the race.

### Verification

**ALWAYS verify this fix is in place before building mobile libraries for v1.13.0+:**

```bash
grep -A 3 "interfaceMonitor.Start" route/network.go | grep -q "UpdateInterfaces"
if [ $? -ne 0 ]; then
    echo "WARNING: Network interface race condition fix is MISSING!"
    echo "Remote rule-set downloads will fail on Android/iOS."
    echo "Apply the fix to route/network.go before building."
fi
```

### Why It Only Affects Mobile (Not OpenWrt/Linux)

- **Android/iOS**: Use `PlatformInterface` with async gomobile callbacks for network monitoring. The deferred `Handler.post()` / dispatch creates the race window.
- **Linux/OpenWrt**: Use Go's standard `net.Interfaces()` which is synchronous. No platform interface, no async callback, no race.

### Additional v1.13.0+ Config Compatibility Notes

**Legacy inbound fields removed:** `sniff`, `sniff_override_destination`, and `domain_strategy` on inbound entries are rejected. Move to route rule actions:
```json
{"action": "sniff"}
```

**`StartOrReloadService` nil options crash:** Never pass `nil`/`null` for the `OverrideOptions` parameter. Always pass an empty instance:
- Kotlin: `commandServer.startOrReloadService(config, OverrideOptions())`
- Swift: `commandServer.startOrReloadService(config, options: LibboxOverrideOptions())`

**gomobile Swift name translation:** The Go method `WriteConnectionEvents` maps to `write(_:)` in Swift (not `writeConnectionEvents(_:)`), because Swift strips redundant type info from ObjC selectors.

**UIKit dependency:** v1.13.0+ includes gRPC which references `UIApplication` and `UIBackgroundTaskInvalid`. iOS extension targets (PacketTunnel) must link `UIKit.framework` even though they don't use it directly.

## CRITICAL: Cronet/NaiveProxy Private Apple API Symbols (App Store Rejection)

### The Problem

The `with_naive_outbound` build tag pulls in `sagernet/cronet-go`, which statically links `libcronet.a` (Chromium's Cronet networking library). The **macOS** variant of `libcronet.a` contains object files that reference private Apple API symbols:

| Object File | Private Symbol | Status |
|---|---|---|
| `info_plist_data.o` | `__kCFBundleNumericVersionKey` | Causes App Store rejection |
| `launch_application.o` | `__kLSOpenOptionBackgroundLaunchKey` | Not yet flagged, but private |

These symbols are **undefined externals** (imports resolved from `CoreFoundation.framework` at runtime). Apple's automated review scanner flags them as non-public API usage, rejecting the binary.

The **iOS** `libcronet.a` does NOT contain these object files — only the macOS (`darwin_arm64`, `darwin_amd64`) variants do.

### Why It Happens

The dependency chain:
```
build tag: with_naive_outbound
  → sagernet/cronet-go
    → cronet-go/lib/darwin_arm64/libcronet.a
      → info_plist_data.o → __kCFBundleNumericVersionKey
      → launch_application.o → __kLSOpenOptionBackgroundLaunchKey
```

gomobile's `mergeStaticLibraries()` pulls `libcronet.a` into `Libbox.framework` via `libtool`. Both the main app binary and any network extension that link `Libbox.xcframework` inherit these symbols.

### The Fix (Applied 2026-04-08)

**Exclude `with_naive_outbound` from Apple builds** in `cmd/internal/build_libbox/main.go`:

```go
// In buildApple():
appleSharedTags := filterTags(sharedTags, "with_naive_outbound")
tags := append(appleSharedTags, darwinTags...)
```

This is safe because:
- NaiveProxy outbound is not user-facing in most downstream apps (not in their protocol lists, product enums, or proxy-chain config). If your app *does* surface NaiveProxy, skip this exclusion and instead patch upstream as described below.
- The Android legacy variant already uses this exact pattern: `filterTags(sharedTags, "with_naive_outbound")`
- iOS was already unaffected (iOS `libcronet.a` lacks the problematic objects)

### Why NOT to Strip Individual Object Files

Do NOT use `ar -d libcronet.a info_plist_data.o` as a fix. Other objects in `libcronet.a` (`code_signature.o`, `mach_port_rendezvous_mac.o`, `process_requirement.o`) depend on `base::mac::OuterBundleCachedInfoPlistData()` exported by `info_plist_data.o`. Stripping it causes linker failures or runtime crashes.

### Post-Build Verification (MANDATORY for App Store builds)

After every Apple Libbox build, run:

```bash
# Check the macOS slice for private API symbols
nm -um Libbox.xcframework/macos-arm64_x86_64/Libbox.framework/Versions/A/Libbox \
  | grep -E '__kCFBundleNumericVersionKey|__kLSOpenOptionBackgroundLaunchKey'
# MUST produce NO output

# Also check iOS (should already be clean)
nm -um Libbox.xcframework/ios-arm64/Libbox.framework/Versions/A/Libbox \
  | grep -E '__kCFBundleNumericVersionKey|__kLSOpenOptionBackgroundLaunchKey'
# MUST produce NO output
```

The `build_macos_appstore.sh` script includes an automated gate that scans the archive binaries and aborts before upload if private API symbols are detected.

### Future Fix

The proper upstream fix is to patch `sagernet/cronet-go` to exclude `info_plist_data.o` and `launch_application.o` from macOS builds (matching the iOS build's behavior). Once fixed upstream, `with_naive_outbound` can be restored for Apple builds if NaiveProxy becomes user-facing.

## Build Workflows

### 1. CLI Binary (Standard)

**Default build tags vary by sing-box version.** Always read them from the repo before building:

```bash
# 1. Check the actual default tags for THIS version
grep '^TAGS ?=' Makefile

# 2. Verify Go version
go version
head -5 go.mod

# 3. Simple build (uses Makefile defaults — safest option)
make

# Or install to $GOBIN
make install

# 4. Custom tags build (use the TAGS from step 1, modify as needed)
TAGS="$(grep '^TAGS ?=' Makefile | sed 's/TAGS ?= //')" make

# 5. Manual build with full flags (read TAGS from Makefile first)
GOTOOLCHAIN=local go build -v -trimpath \
  -tags "$(grep '^TAGS ?=' Makefile | sed 's/TAGS ?= //')" \
  -ldflags "-X 'github.com/sagernet/sing-box/constant.Version=$(git describe --tags)' -s -w -buildid=" \
  ./cmd/sing-box
```

**Do NOT hardcode build tags.** Different versions add or remove tags. Always read `TAGS ?=` from the Makefile as the source of truth. For mobile builds, the tags are defined in `cmd/internal/build_libbox/main.go` (the `sharedTags` variable).

### 2. Android Library (libbox.aar)

**Prerequisites:**
- Go (matching `go.mod` requirement)
- OpenJDK 17 (`JAVA_HOME` set)
- Android SDK (`ANDROID_HOME` set)
- Android NDK r28 / `28.0.13004108` (preferred for reproducibility)
- SagerNet gomobile: check `Makefile` for the pinned version (`make lib_install`)

```bash
# Install gomobile tooling (version pinned in Makefile)
make lib_install

# Build Android AAR
make lib_android
```

**v1.13.0+ note:** `make lib_android` now builds TWO variants: `libbox.aar` (SDK 23) and `libbox-legacy.aar` (SDK 21). Most apps only need the main `libbox.aar`; pick the legacy variant only if you ship to SDK 21–22 devices.

### 3. Apple Library (Libbox.xcframework)

**Prerequisites:**
- macOS with Xcode installed
- Go (matching `go.mod` requirement)
- SagerNet gomobile installed (see above)

```bash
# Install gomobile tooling
make lib_install

# Full Apple (iOS + tvOS + macOS + simulators)
make lib_apple
```

**v1.13.0+ note:** The xcframework now includes simulator slices (`iossimulator`, `tvossimulator`). Only device slices need code signing.

**After building, re-sign for your app's distribution identity** (codesign with your Developer ID / Distribution cert, then re-zip the framework if your downstream tooling expects a zipped xcframework). The exact resign script is app-specific — sing-box's build pipeline ships unsigned binaries.

**After building, ALWAYS verify no private Apple API symbols leaked in (see CRITICAL section below):**
```bash
nm -um Libbox.xcframework/macos-arm64_x86_64/Libbox.framework/Versions/A/Libbox | grep -E '__kCFBundle|__kLS'
# Must produce NO output. Any match = App Store rejection.
```

### 4. Docker Image

```bash
# Standard Docker build (uses golang:1.25-alpine, CGO_ENABLED=0)
docker build -t sing-box .

# Multi-platform
docker buildx build --platform linux/amd64,linux/arm64 -t sing-box .
```

## Build Tags Reference

For the full catalog of all known tags and their meanings, see `references/build_tags.md`.

**Default tags change across versions.** To discover the current defaults for any checkout:

| Source | What It Tells You | How to Read |
|---|---|---|
| `Makefile` line `TAGS ?=` | CLI binary default tags | `grep '^TAGS ?=' Makefile` |
| `cmd/internal/build_libbox/main.go` `sharedTags` | Mobile library tags | Read the `sharedTags` slice |
| `release/DEFAULT_BUILD_TAGS` (if exists) | Packager reference tags | `cat release/DEFAULT_BUILD_TAGS` |
| `.goreleaser.yaml` `flags` section | Release binary tags | Read the goreleaser config |

Key rules:
- **Do not hardcode or assume default tags** — always read them from the repo
- **Do not change default tags** unless certain about what is being added/removed
- `with_embedded_tor` requires CGO and system libraries — poorly supported, avoid
- `with_naive_outbound` has complex platform-specific requirements (see references)
- `with_ech` is automatic with Go 1.24+ (no explicit tag needed)

## Troubleshooting

For detailed troubleshooting of all known build failures and solutions, see `references/troubleshooting.md`.

**Quick fixes for the most common issues:**

| Error | Fix |
|---|---|
| `go.mod requires go >= X.Y.Z` | Install correct Go version. `GOTOOLCHAIN=local` prevents auto-download. |
| `//go:linkname must refer to declared function` | Add `-ldflags "-checklinkname=0"` |
| `missing gomobile installation` | Run `make lib_install` (uses Makefile-pinned version) |
| `android SDK not found` | Set `ANDROID_HOME` env var |
| `android NDK not found` | Install NDK r28 or set `ANDROID_NDK_HOME` |
| `java version should be openjdk 17` | Install OpenJDK 17, set `JAVA_HOME` |
| `unknown field Inet4LoopbackAddress` | Dependency mismatch — run `go mod tidy`, do NOT update individual deps |
| Git tag errors during version detection | `git fetch --tags` |
| `no available network interface` (Android/iOS) | Apply the race condition fix in `route/network.go` — see section above |
| `legacy inbound fields are deprecated` | Remove `sniff`, `sniff_override_destination`, `domain_strategy` from inbound configs; use route rule actions instead |
| `Undefined symbol: _OBJC_CLASS_$_UIApplication` (iOS) | Add `UIKit.framework` to the extension target's linked frameworks |
| `'writeConnectionEvents' has been renamed to 'write(_:)'` | gomobile Swift translation — use `write(_:)` not `writeConnectionEvents(_:)` |
| nil pointer in `StartOrReloadService` | Pass `OverrideOptions()` / `LibboxOverrideOptions()`, never nil/null |
| App Store rejection: `__kCFBundleNumericVersionKey` | Remove `with_naive_outbound` from Apple build tags — it pulls in Cronet which has private API symbols. See CRITICAL section above. |

## Windows 7 Legacy Builds (Special Case)

Only needed for Windows 7 targets. Requires a patched Go toolchain from [MetaCubeX/go](https://github.com/MetaCubeX/go) that reverts Windows 7 API removals. See `references/windows7_legacy.md` for details.

## Pre-Build Checklist

Run `scripts/preflight.sh` before building to validate the environment automatically:

```bash
bash /path/to/skill/scripts/preflight.sh
```

The script checks: Go version, go.mod compatibility, git tags, gomobile, Java version, Android SDK/NDK, and build configuration.

**For v1.13.0+ mobile builds, also verify the race condition fix:**
```bash
grep -A 3 "interfaceMonitor.Start" route/network.go | grep -q "UpdateInterfaces" && echo "Race fix: OK" || echo "Race fix: MISSING — apply before building!"
```

**For Apple builds, verify `with_naive_outbound` is excluded (private API check):**
```bash
# Check that buildApple() uses filterTags to exclude with_naive_outbound
grep -A 2 "appleSharedTags" cmd/internal/build_libbox/main.go | grep -q "with_naive_outbound" && echo "Naive exclusion: OK" || echo "WARNING: with_naive_outbound not excluded from Apple build — will cause App Store rejection!"
```

**After Apple builds, scan for private API symbols:**
```bash
nm -um Libbox.xcframework/macos-arm64_x86_64/Libbox.framework/Versions/A/Libbox | grep -E '__kCFBundle|__kLS' && echo "FAIL: Private API symbols found!" || echo "Private API scan: CLEAN"
```
