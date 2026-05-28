# Windows 7 Legacy Build

## Overview

Standard Go 1.23+ dropped Windows 7 support by removing legacy Windows APIs. To produce binaries that run on Windows 7, sing-box uses a **patched Go toolchain** from [MetaCubeX/go](https://github.com/MetaCubeX/go).

## When This Is Needed

**Only** when building sing-box binaries that must run on Windows 7. For all other targets (Linux, macOS, modern Windows 10+, Android, iOS), use the standard Go toolchain.

## What the Patches Do

Four specific upstream Go commits are reverted:

1. **crypto/rand**: Reverts `ProcessPrng` API usage (Windows 7 lacks `ProcessPrng`)
2. **net**: Reverts socket changes that require newer Windows APIs
3. **syscall**: Reverts console handle workaround removal
4. **runtime**: Reverts `LoadLibraryEx` system library loading changes

## Setup

The CI workflow (`.github/setup_go_for_windows7.sh`) automates this:

```bash
# Downloads Go source and applies reverse patches
VERSION="1.25.3"
wget https://go.dev/dl/go${VERSION}.linux-amd64.tar.gz
tar xf go${VERSION}.linux-amd64.tar.gz
mv go go_win7

# Apply 4 reverse patches from MetaCubeX/go
for commit in <commit_hash_1> <commit_hash_2> <commit_hash_3> <commit_hash_4>; do
    wget https://github.com/MetaCubeX/go/commit/${commit}.patch
    cd go_win7 && git apply ../${commit}.patch && cd ..
done
```

The patched Go is stored at `~/go/go_win7/` and used via:
```yaml
env:
  - GOROOT=$GOPATH/go_win7
tool: $GOPATH/go_win7/bin/go
```

## Building Manually

1. Clone or download Go source matching your target version
2. Download the corresponding patches from MetaCubeX/go
3. Apply patches: `git apply <patch_file>`
4. Build Go from source or use the patched binary
5. Set `GOROOT` to the patched Go directory
6. Build sing-box with the patched `go` binary

## goreleaser Configuration

In `.goreleaser.yaml`, the legacy build is defined as:

```yaml
- id: legacy
  env:
    - CGO_ENABLED=0
    - GOROOT={{ .Env.GOPATH }}/go_legacy
  tool: "{{ .Env.GOPATH }}/go_legacy/bin/go"
  targets:
    - windows_amd64_v1
    - windows_386
```

Only `windows_amd64_v1` and `windows_386` get legacy builds.
