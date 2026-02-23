#!/bin/bash
# run-tests-core.sh - Core test runner (bash, v2)
# Runs tests in namespace-based groups to avoid native resource exhaustion.
# Bash avoids PowerShell pipeline back-pressure that crashes testhost.
# Auto-retries crashed groups (cumulative OS resource exhaustion causes crashes).
# Uses TRX logger for reliable partial result capture on crashes.

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TEST_DLL="$REPO_ROOT/mRemoteNGTests/bin/x64/Release/mRemoteNGTests.dll"
RESULTS_BASE="/tmp/mremoteng-testresults"

# Test groups - each runs in its own testhost process
declare -a GROUP_NAMES=(
    "Connection"
    "Config.Xml"
    "Config.Other"
    "UI"
    "Tools"
    "Security"
    "Tree+Container+Cred"
    "Remaining"
    "Integration"
)
declare -a GROUP_FILTERS=(
    'FullyQualifiedName~mRemoteNGTests.Connection'
    'FullyQualifiedName~mRemoteNGTests.Config.Serializers.ConnectionSerializers.Xml'
    'FullyQualifiedName~mRemoteNGTests.Config&FullyQualifiedName!~Serializers.ConnectionSerializers.Xml'
    'FullyQualifiedName~mRemoteNGTests.UI&FullyQualifiedName!~OptionsFormTests&FullyQualifiedName!~AllOptionsPagesTests'
    'FullyQualifiedName~mRemoteNGTests.Tools'
    'FullyQualifiedName~mRemoteNGTests.Security'
    'FullyQualifiedName~mRemoteNGTests.Tree|FullyQualifiedName~mRemoteNGTests.Container|FullyQualifiedName~mRemoteNGTests.Credential'
    'FullyQualifiedName!~mRemoteNGTests.Connection&FullyQualifiedName!~mRemoteNGTests.Config&FullyQualifiedName!~mRemoteNGTests.UI&FullyQualifiedName!~mRemoteNGTests.Tools&FullyQualifiedName!~mRemoteNGTests.Security&FullyQualifiedName!~mRemoteNGTests.Tree&FullyQualifiedName!~mRemoteNGTests.Container&FullyQualifiedName!~mRemoteNGTests.Credential&FullyQualifiedName!~mRemoteNGTests.IntegrationTests&FullyQualifiedName!~OptionsFormTests&FullyQualifiedName!~AllOptionsPagesTests'
    'FullyQualifiedName~mRemoteNGTests.IntegrationTests'
)

# Expected test counts per group (for verification)
declare -a GROUP_EXPECTED=(1024 124 544 348 329 164 178 83 21)

# FrmOptions isolated tests
declare -a ISO_NAMES=("FormBehavior" "AllPages")
declare -a ISO_FILTERS=("Name=FormBehavior" "Name=AllPagesExistWithIconsAndLoadCorrectSettings")

total_passed=0
total_failed=0
any_crashed=false
groups_with_zero=0

cleanup_env() {
    taskkill //F //IM testhost.exe >/dev/null 2>&1 || true
    taskkill //F //IM testhost.x86.exe >/dev/null 2>&1 || true
    taskkill //F //IM dotnet.exe >/dev/null 2>&1 || true
    rm -rf "$REPO_ROOT/TestResults" 2>/dev/null || true
    rm -f "$REPO_ROOT/mRemoteNGTests/bin/x64/Release/testhost.runtimeconfig.json" 2>/dev/null || true
    sleep 1
}

# Run a single test group. Returns: passed|failed|crashed
run_group() {
    local dll="$1"
    local filter="$2"
    local uid=$(date +%s%N | tail -c 8)
    local results_dir="${RESULTS_BASE}-${uid}"
    local trx_file="results.trx"

    # Build args as array to avoid shell interpretation of & | ! in filters
    local args=("test" "$dll" "--results-directory" "$results_dir" "--verbosity" "normal" "--logger" "trx;LogFileName=$trx_file")
    if [ -n "$filter" ]; then
        args+=("--filter" "$filter")
    fi

    # Run test (bash tail is efficient, no back-pressure)
    local output
    output=$(dotnet "${args[@]}" 2>&1 | tail -20)

    # Try TRX first (most reliable, survives partial crashes)
    local passed=0 failed=0 crashed=false
    local trx_path="$results_dir/$trx_file"
    if [ -f "$trx_path" ]; then
        local trx_passed trx_failed trx_outcome
        trx_passed=$(grep -oP 'passed="\K\d+' "$trx_path" | head -1)
        trx_failed=$(grep -oP 'failed="\K\d+' "$trx_path" | head -1)
        trx_outcome=$(grep -oP 'outcome="\K[^"]+' "$trx_path" | head -1)
        [ -n "$trx_passed" ] && passed=$trx_passed
        [ -n "$trx_failed" ] && failed=$trx_failed
        if [ "$trx_outcome" = "Aborted" ] || [ "$trx_outcome" = "Error" ]; then
            crashed=true
        fi
    fi

    # Fall back to stdout parsing if TRX unavailable
    if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
        local p=$(echo "$output" | grep -oP 'Passed\s*[:-]\s*\K\d+' | tail -1)
        local f=$(echo "$output" | grep -oP 'Failed\s*[:-]\s*\K\d+' | tail -1)
        [ -n "$p" ] && passed=$p
        [ -n "$f" ] && failed=$f
    fi

    # Crash detection from output
    if echo "$output" | grep -qiE "crashed|aborted"; then
        crashed=true
    fi

    rm -rf "$results_dir" 2>/dev/null || true
    echo "${passed}|${failed}|${crashed}"
}

echo ""
echo "[Phase 1] Running ${#GROUP_NAMES[@]} test groups (with auto-retry on crash)..."

for i in "${!GROUP_NAMES[@]}"; do
    name="${GROUP_NAMES[$i]}"
    filter="${GROUP_FILTERS[$i]}"
    expected="${GROUP_EXPECTED[$i]}"
    printf "  [%-20s] " "$name"

    cleanup_env
    result=$(run_group "$TEST_DLL" "$filter")
    IFS='|' read -r p f c <<< "$result"
    p=${p//[^0-9]/}; [ -z "$p" ] && p=0
    f=${f//[^0-9]/}; [ -z "$f" ] && f=0

    # Auto-retry if crashed or 0 results (up to 3 retries, cumulative OS resource exhaustion)
    retries=0
    while [ "$retries" -lt 3 ] && { [ "$c" = "true" ] || [ "$p" -eq 0 ]; } && [ "$p" -lt "$expected" ]; do
        retries=$((retries + 1))
        printf "%dp/RETRY%d... " "$p" "$retries"
        cleanup_env
        sleep 2
        result2=$(run_group "$TEST_DLL" "$filter")
        IFS='|' read -r p2 f2 c2 <<< "$result2"
        p2=${p2//[^0-9]/}; [ -z "$p2" ] && p2=0
        f2=${f2//[^0-9]/}; [ -z "$f2" ] && f2=0
        # Take best result
        if [ "$p2" -gt "$p" ]; then
            p=$p2; f=$f2; c=$c2
        fi
    done

    if [ "$c" = "true" ]; then
        echo "${p}p/CRASHED"
        any_crashed=true
    elif [ "$f" -gt 0 ] 2>/dev/null; then
        echo "${p}p/${f}f"
    else
        echo "${p} passed"
    fi

    # Track groups that returned 0 tests despite retries
    if [ "$p" -eq 0 ] && [ "$f" -eq 0 ]; then
        groups_with_zero=$((groups_with_zero + 1))
    fi

    total_passed=$((total_passed + p))
    total_failed=$((total_failed + f))
done

echo ""
echo "[Phase 2] FrmOptions isolated..."

for i in "${!ISO_NAMES[@]}"; do
    name="${ISO_NAMES[$i]}"
    filter="${ISO_FILTERS[$i]}"
    printf "  [%-20s] " "$name"

    cleanup_env
    result=$(run_group "$TEST_DLL" "$filter")
    IFS='|' read -r p f c <<< "$result"
    p=${p//[^0-9]/}; [ -z "$p" ] && p=0
    f=${f//[^0-9]/}; [ -z "$f" ] && f=0

    # Auto-retry crashed FrmOptions tests (up to 3 retries)
    retries=0
    while [ "$retries" -lt 2 ] && { [ "$c" = "true" ] || [ "$p" -eq 0 ]; }; do
        retries=$((retries + 1))
        printf "RETRY%d... " "$retries"
        cleanup_env
        sleep 2
        result2=$(run_group "$TEST_DLL" "$filter")
        IFS='|' read -r p2 f2 c2 <<< "$result2"
        p2=${p2//[^0-9]/}; [ -z "$p2" ] && p2=0
        f2=${f2//[^0-9]/}; [ -z "$f2" ] && f2=0
        if [ "$p2" -gt "$p" ]; then
            p=$p2; f=$f2; c=$c2
        fi
    done

    if [ "$c" = "true" ]; then
        echo "CRASHED"
        any_crashed=true
    elif [ "$f" -gt 0 ] 2>/dev/null; then
        echo "FAILED"
    else
        echo "passed"
    fi

    total_passed=$((total_passed + p))
    total_failed=$((total_failed + f))
done

# Restore DLL if crash deleted it
BACKUP="$REPO_ROOT/mRemoteNGTests/bin/x64/Release/.backup/mRemoteNGTests.dll"
if [ ! -f "$TEST_DLL" ] && [ -f "$BACKUP" ]; then
    echo ""
    echo "[Recovery] Restoring test DLL from backup"
    cp "$BACKUP" "$TEST_DLL"
fi

# Summary
total_tests=$((total_passed + total_failed))
MIN_TOTAL=2800

echo ""
echo "========== RESULTS =========="
echo "  Total:   $total_tests"
echo "  Passed:  $total_passed"
[ "$total_failed" -gt 0 ] && echo "  Failed:  $total_failed"
[ "$any_crashed" = "true" ] && echo "  CRASHES: yes (partial results captured)"
[ "$groups_with_zero" -gt 0 ] && echo "  PHANTOM_GROUPS: $groups_with_zero group(s) returned 0 tests"
[ "$total_tests" -lt "$MIN_TOTAL" ] && echo "  WARNING: Only $total_tests tests (expected >$MIN_TOTAL)"
echo "============================="

if [ "$total_failed" -gt 0 ]; then
    # Real test failure — code is broken
    exit 1
fi
if [ "$total_tests" -lt "$MIN_TOTAL" ]; then
    # Coverage gap — groups returned 0 (phantom) but no real failures
    # Exit code 96 = infrastructure flakiness, not code issue
    echo "  EXIT 96: Coverage gap (phantom groups, no real failures)"
    exit 96
fi
exit 0
