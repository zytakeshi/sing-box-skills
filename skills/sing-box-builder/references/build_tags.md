# sing-box Build Tags — Complete Reference

## Default Tags

**Default tags change across sing-box versions.** Never hardcode them. Always read the source of truth:

```bash
# CLI binary defaults — read from Makefile
grep '^TAGS ?=' Makefile

# Mobile library defaults — read from build_libbox
grep -A5 'sharedTags' cmd/internal/build_libbox/main.go

# Packager reference files (may not exist in all versions)
cat release/DEFAULT_BUILD_TAGS 2>/dev/null
cat release/DEFAULT_BUILD_TAGS_WINDOWS 2>/dev/null
cat release/DEFAULT_BUILD_TAGS_OTHERS 2>/dev/null
```

## All Known Feature Tags

Whether a tag is "default" depends on the sing-box version. Check the Makefile `TAGS ?=` line.

| Tag | Purpose | CGO Required? | Notes |
|---|---|---|---|
| `with_gvisor` | gVisor user-space TCP/IP stack for TUN/WireGuard | No | Enables userspace networking |
| `with_quic` | QUIC/HTTP3/Hysteria/TUIC transport | No | Requires Go 1.20+ |
| `with_dhcp` | DHCP DNS transport | No | |
| `with_wireguard` | WireGuard outbound | No | |
| `with_utls` | uTLS browser fingerprinting for TLS | No | Requires Go 1.20+ |
| `with_acme` | ACME/Let's Encrypt certificate issuer | No | |
| `with_clash_api` | Clash-compatible REST API + dashboard | No | |
| `with_tailscale` | Tailscale endpoint integration | No | Excluded from lint tags |
| `with_grpc` | Standard gRPC transport for V2Ray | No | "Good compatibility but poor performance" |
| `with_v2ray_api` | V2Ray statistics/routing API | No | |
| `with_embedded_tor` | Embedded Tor support | **Yes** | Requires libssl-dev + libevent-dev; poorly supported |
| `with_reality_server` | REALITY server support | No | |
| `with_ech` | Encrypted Client Hello | No | Automatically enabled with Go 1.24+ via build constraint |
| `with_conntrack` | Connection tracking | No | Used in mobile library builds |
| `with_low_memory` | Low memory mode | No | Reduces memory on constrained devices (iOS/tvOS) |
| `with_naive_outbound` | NaiveProxy outbound | Platform-dependent | See NaiveProxy section below |
| `with_purego` | Pure Go crypto/bindings | No | Use with `with_naive_outbound` on Windows/Linux |
| `with_musl` | Statically linked musl build | **Yes** | Linux-only, use with `with_naive_outbound` |
| `badlinkname` | Enable `go:linkname` access to internal stdlib kTLS APIs | No | Needed because Go stdlib does not expose low-level kTLS functions |
| `tfogo_checklinkname0` | Companion to `badlinkname` | No | Bypasses Go 1.23+ linker `go:linkname` restrictions |
| `with_ccm` | Claude Code Multiplexer service | No | |
| `with_ocm` | OpenAI Codex Multiplexer service | No | |
| `debug` | Debug mode for mobile builds | No | |

## Platform-Specific Default Tags

Some versions include reference files in `release/`:

| File | Platform | Notes |
|---|---|---|
| `release/DEFAULT_BUILD_TAGS` | Linux/Darwin/Android | May not exist in all versions |
| `release/DEFAULT_BUILD_TAGS_WINDOWS` | Windows | Usually includes `with_purego` |
| `release/DEFAULT_BUILD_TAGS_OTHERS` | Other platforms | Usually excludes `with_naive_outbound` |

Always check if these files exist before relying on them: `ls release/DEFAULT_BUILD_TAGS* 2>/dev/null`

## Mobile Library Tags

Mobile tags are defined in `cmd/internal/build_libbox/main.go` in the `sharedTags` variable. They differ from CLI binary tags. Always read them from source:

```bash
grep -A10 'sharedTags' cmd/internal/build_libbox/main.go
```

General patterns (verify against the actual source):
- **Android**: shared tags + `with_tailscale`
- **Apple iOS/tvOS**: shared tags + `with_dhcp` + `with_low_memory`
- **Apple macOS**: shared tags + `with_dhcp` + `with_tailscale`

## NaiveProxy Outbound (`with_naive_outbound`) — Platform Requirements

### Windows (amd64, arm64)
- Use `with_purego` tag
- Requires `libcronet.dll` in binary directory or PATH
- Official sing-box releases include `libcronet.dll` in the archive
- For self-built binaries, download from cronet-go releases

### Linux purego (amd64, arm64 only)
- Use `with_purego` tag
- Requires `libcronet.so` in binary directory or system library path
- Official sing-box releases include `libcronet.so` in the archive
- For self-built binaries, download from cronet-go releases

### Linux CGO (386, amd64, arm, arm64)
- Requires Chromium toolchain
- glibc builds need glibc >= 2.31 at runtime
- musl builds: add `with_musl` tag (statically linked, no runtime deps)

### Apple platforms
- Requires Xcode and CGO
- See cronet-go documentation

### Android
- Requires Android NDK and CGO
- See cronet-go documentation

## Warning

From official docs: "It is not recommended to change the default build tag list unless you really know what you are adding."
