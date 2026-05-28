# sing-box Build Troubleshooting

## Failure 1: Go Version Mismatch

**Error:**
```
go: go.mod requires go >= 1.23.1 (running go 1.22.x; GOTOOLCHAIN=local)
```

**Cause:** The Makefile sets `GOTOOLCHAIN=local` which prevents Go from automatically downloading a newer toolchain. The installed Go version does not meet the minimum specified in `go.mod`.

**Fix:**
1. Check the required version: `head -5 go.mod`
2. Install the correct Go version from https://go.dev/dl/
3. Verify: `go version`

**Do NOT:**
- Override `GOTOOLCHAIN` to `auto` — this defeats reproducibility
- Downgrade the `go.mod` version — this will break dependencies

---

## Failure 2: Linkname Restriction (Go 1.23+)

**Error:**
```
//go:linkname must refer to declared function or variable
link: invalid reference to ...
```

**Cause:** Go 1.23 made `-checklinkname=1` the default, blocking unauthorized `//go:linkname` to stdlib internals. sing-box uses linkname directives in multiple files.

**Fix:** Add `-checklinkname=0` to ldflags:
```bash
go build -ldflags "-checklinkname=0" ./cmd/sing-box
```

The Makefile and `cmd/internal/build_libbox/main.go` already include this flag for mobile builds. For manual CLI builds, add it explicitly.

---

## Failure 3: Missing gomobile

**Error:**
```
missing gomobile installation
```

**Cause:** Mobile library builds require SagerNet's fork of gomobile, NOT the official `golang.org/x/mobile`.

**Fix:**
```bash
go install -v github.com/sagernet/gomobile/cmd/gomobile@v0.1.8
go install -v github.com/sagernet/gomobile/cmd/gobind@v0.1.8
```

Or use the Makefile:
```bash
make lib_install
```

**Do NOT install** `golang.org/x/mobile/cmd/gomobile` — it lacks required features like per-platform tags and xcframework improvements.

---

## Failure 4: Android SDK/NDK Not Found

**Error:**
```
android SDK not found
android NDK not found
```

**Cause:** The build system searches for the SDK in specific locations.

**Fix:** Set environment variables:
```bash
export ANDROID_HOME=~/Library/Android/sdk  # or your SDK path
export ANDROID_NDK_HOME=$ANDROID_HOME/ndk/28.0.13004108
```

SDK search paths (in order):
1. `$ANDROID_HOME`
2. `~/Android/Sdk`
3. `~/.local/lib/android/sdk`
4. `~/Library/Android/sdk`

**Preferred NDK version:** `28.0.13004108` (NDK r28). Other versions work but emit a reproducibility warning.

---

## Failure 5: Wrong Java Version

**Error:**
```
java version should be openjdk 17
```

**Cause:** Android libbox builds hard-check for OpenJDK 17.

**Fix:**
```bash
# macOS (Homebrew)
brew install openjdk@17
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

# Linux
sudo apt install openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

---

## Failure 6: Git Tag Not Found

**Error:**
```
fatal: No names found, cannot describe anything.
```

**Cause:** The build system runs `git describe --tags` to determine the version. Shallow clones or repos without tags will fail.

**Fix:**
```bash
git fetch --tags
```

For shallow clones:
```bash
git fetch --unshallow --tags
```

---

## Failure 7: Embedded Tor Build Failures

**Error:**
```
fatal error: openssl/opensslv.h: No such file or directory
fatal error: event2/event.h: No such file or directory
```

**Cause:** `with_embedded_tor` requires CGO and system libraries.

**Fix:**
```bash
# Debian/Ubuntu
sudo apt install libssl-dev libevent-dev

# macOS
brew install openssl libevent
```

**Warning:** May still fail with OpenSSL 3.x due to API incompatibilities. This feature is poorly supported — the upstream issue was closed as "not planned." Consider avoiding `with_embedded_tor`.

---

## Failure 8: Dependency Version Mismatch

**Error:**
```
unknown field Inet4LoopbackAddress in struct literal
```

**Cause:** Manually updating individual dependencies breaks API compatibility between sing-box's forked packages.

**Fix:**
```bash
go mod tidy
```

**Do NOT:**
- Run `go get` to update individual forked dependencies (sagernet/*, metacubex/*)
- Substitute upstream library versions for forked versions
- Mix dependency versions from different branches

---

## Failure 9: Multipath TCP Issues (Go 1.24+)

**Symptom:** Unexpected network behavior on listeners after upgrading to Go 1.24+.

**Cause:** Go 1.24 enables Multipath TCP on listeners by default. sing-box has its own MPTCP control via the `tcp_multi_path` configuration option and disables Go's default with a GODEBUG setting to avoid conflicts.

**Fix:** Include in ldflags:
```bash
-X 'internal/godebug.defaultGODEBUG=multipathtcp=0'
```

This ensures sing-box's own `tcp_multi_path` option remains the sole controller of MPTCP behavior.

---

## Failure 10: Cross-Compilation NDK Errors

**Error:**
```
armv7a-linux-androideabi21-clang: command not found
```

**Cause:** Android NDK cross-compiler toolchains are not in PATH.

**Fix:** Ensure NDK toolchain bin directory is in PATH:
```bash
export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64/bin:$PATH
```

**Cross-compiler mappings:**

| GOARCH | CC | CXX |
|---|---|---|
| arm (v7) | `armv7a-linux-androideabi21-clang` | `armv7a-linux-androideabi21-clang++` |
| arm64 | `aarch64-linux-android21-clang` | `aarch64-linux-android21-clang++` |
| amd64 | `x86_64-linux-android21-clang` | `x86_64-linux-android21-clang++` |
| 386 | `i686-linux-android21-clang` | `i686-linux-android21-clang++` |

---

## Failure 11: macOS Code Signing / Notarization

**Symptom:** Apple build produces xcframework but Xcode rejects it or it fails notarization.

**Cause:** gomobile bind output may lack proper signing or framework metadata.

**Workaround:** Rebuild with explicit signing identity via Xcode, or use `codesign` manually after the gomobile bind step. This is an ongoing area of improvement in sagernet/gomobile.

---

## Failure 12: Docker Build Architecture Mismatch

**Symptom:** Docker image built on ARM Mac doesn't work on x86_64 server (or vice versa).

**Fix:** Use Docker Buildx with explicit platform targeting:
```bash
docker buildx build --platform linux/amd64 -t sing-box .
```

Supported platforms for Docker multi-platform builds:
`linux/amd64`, `linux/arm/v6`, `linux/arm/v7`, `linux/arm64`, `linux/386`, `linux/ppc64le`, `linux/riscv64`, `linux/s390x`
