#!/usr/bin/env bash
# sing-box Build Environment Preflight Check
# Run this before building to validate your environment.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC}: $1"; ((WARNINGS++)); }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; ((ERRORS++)); }

echo "=== sing-box Build Environment Preflight Check ==="
echo ""

# 1. Check Go installation
echo "[Go Toolchain]"
if command -v go &>/dev/null; then
    GO_VERSION=$(go version | grep -oP 'go\K[0-9]+\.[0-9]+(\.[0-9]+)?' || go version | sed 's/.*go\([0-9]*\.[0-9]*\.*[0-9]*\).*/\1/')
    pass "Go installed: go${GO_VERSION}"
else
    fail "Go is not installed. Install from https://go.dev/dl/"
fi

# 2. Check go.mod minimum version
if [ -f "go.mod" ]; then
    REQUIRED_GO=$(grep '^go ' go.mod | awk '{print $2}')
    pass "go.mod requires: go${REQUIRED_GO}"

    if command -v go &>/dev/null; then
        # Simple version comparison
        GO_MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
        GO_MINOR=$(echo "$GO_VERSION" | cut -d. -f2)
        REQ_MAJOR=$(echo "$REQUIRED_GO" | cut -d. -f1)
        REQ_MINOR=$(echo "$REQUIRED_GO" | cut -d. -f2)

        if [ "$GO_MAJOR" -gt "$REQ_MAJOR" ] || ([ "$GO_MAJOR" -eq "$REQ_MAJOR" ] && [ "$GO_MINOR" -ge "$REQ_MINOR" ]); then
            pass "Go version meets minimum requirement"
        else
            fail "Go ${GO_VERSION} does not meet minimum go${REQUIRED_GO}. GOTOOLCHAIN=local will block the build."
        fi
    fi
else
    fail "go.mod not found. Are you in the sing-box repository root?"
fi

echo ""

# 3. Check git tags (for version detection)
echo "[Git]"
if command -v git &>/dev/null; then
    if git describe --tags &>/dev/null; then
        TAG=$(git describe --tags)
        pass "Git tag found: ${TAG}"
    else
        warn "No git tags found. Run 'git fetch --tags' to fix version detection."
    fi
else
    fail "Git is not installed"
fi

echo ""

# 4. Check mobile build prerequisites (optional)
echo "[Mobile Build Prerequisites (optional)]"

# gomobile
if command -v gomobile &>/dev/null; then
    pass "gomobile found: $(which gomobile)"
else
    warn "gomobile not installed. Run 'make lib_install' for mobile builds."
fi

# Java (for Android)
if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -1)
    if echo "$JAVA_VER" | grep -q "17"; then
        pass "Java 17 found"
    else
        warn "Java found but not version 17: ${JAVA_VER}. Android builds require OpenJDK 17."
    fi
else
    warn "Java not installed. Required for Android builds."
fi

# Android SDK
if [ -n "${ANDROID_HOME:-}" ] && [ -d "${ANDROID_HOME}" ]; then
    pass "ANDROID_HOME set: ${ANDROID_HOME}"
elif [ -d "$HOME/Library/Android/sdk" ]; then
    pass "Android SDK found at ~/Library/Android/sdk"
elif [ -d "$HOME/Android/Sdk" ]; then
    pass "Android SDK found at ~/Android/Sdk"
else
    warn "Android SDK not found. Set ANDROID_HOME for Android builds."
fi

# Android NDK
if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -d "${ANDROID_NDK_HOME}" ]; then
    pass "ANDROID_NDK_HOME set: ${ANDROID_NDK_HOME}"
    if echo "${ANDROID_NDK_HOME}" | grep -q "28.0.13004108"; then
        pass "Preferred NDK version r28 detected"
    else
        warn "NDK found but not preferred version 28.0.13004108. Reproducibility may vary."
    fi
else
    warn "ANDROID_NDK_HOME not set. Will search SDK paths for Android builds."
fi

echo ""

# 5. Check Makefile tags
echo "[Build Configuration]"
if [ -f "Makefile" ]; then
    DEFAULT_TAGS=$(grep '^TAGS ?=' Makefile | sed 's/TAGS ?= //')
    pass "Default build tags: ${DEFAULT_TAGS}"
else
    warn "Makefile not found"
fi

# 6. Check release reference files
if [ -f "release/LDFLAGS" ]; then
    pass "release/LDFLAGS exists"
else
    warn "release/LDFLAGS not found"
fi

if [ -f "release/DEFAULT_BUILD_TAGS" ]; then
    pass "release/DEFAULT_BUILD_TAGS exists"
else
    warn "release/DEFAULT_BUILD_TAGS not found"
fi

echo ""
echo "=== Summary ==="
echo -e "  Errors:   ${RED}${ERRORS}${NC}"
echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}Build environment has errors. Fix them before building.${NC}"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}Build environment OK with warnings. CLI builds should work.${NC}"
    exit 0
else
    echo -e "${GREEN}Build environment fully ready.${NC}"
    exit 0
fi
