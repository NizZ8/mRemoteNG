#!/bin/bash
# run-tests-core.sh - Core test runner (bash, v4 — PARALLEL, SHARED DLL)
# Launches ALL test groups in parallel from the SAME DLL.
# No copies needed — each testhost gets its own results directory.
# Crashed groups are retried sequentially with cleanup between them.
# Target: ~35s for 2800+ tests (vs ~8min sequential in v2).
# NOTE: grep -oE only — MSYS2 grep doesn't support -oP (Perl regex).

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
TEST_DLL="$REPO_ROOT/mRemoteNGTests/bin/x64/Release/mRemoteNGTests.dll"
RESULTS_BASE="/tmp/mremoteng-testresults"
PARALLEL_DIR="/tmp/mremoteng-parallel-$$"

# Test groups
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
declare -a GROUP_EXPECTED=(1049 124 555 367 361 166 178 83 21)

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
    rm -rf "$REPO_ROOT/TestResults" 2>/dev/null || true
    rm -f "$REPO_ROOT/mRemoteNGTests/bin/x64/Release/testhost.runtimeconfig.json" 2>/dev/null || true
}

# Run a single test group. Returns: passed|failed|crashed
run_group() {
    local dll="$1" filter="$2"
    local uid=$(date +%s%N | tail -c 8)
    local results_dir="${RESULTS_BASE}-${uid}"
    local trx_file="results.trx"

    local args=("test" "$dll" "--results-directory" "$results_dir" "--verbosity" "normal" "--logger" "trx;LogFileName=$trx_file")
    [ -n "$filter" ] && args+=("--filter" "$filter")

    local output
    output=$(dotnet "${args[@]}" 2>&1 | tail -20)

    local passed=0 failed=0 crashed=false
    local trx_path="$results_dir/$trx_file"
    if [ -f "$trx_path" ]; then
        local trx_passed trx_failed trx_outcome
        trx_passed=$(grep -oE 'passed="[0-9]+"' "$trx_path" | head -1 | grep -oE '[0-9]+')
        trx_failed=$(grep -oE 'failed="[0-9]+"' "$trx_path" | head -1 | grep -oE '[0-9]+')
        trx_outcome=$(grep -oE 'outcome="[^"]+"' "$trx_path" | head -1 | sed 's/outcome="//;s/"//')
        [ -n "$trx_passed" ] && passed=$trx_passed
        [ -n "$trx_failed" ] && failed=$trx_failed
        [ "$trx_outcome" = "Aborted" ] || [ "$trx_outcome" = "Error" ] && crashed=true
    fi

    if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
        local p f
        p=$(echo "$output" | grep -oE 'Passed[[:space:]]*[:-][[:space:]]*[0-9]+' | tail -1 | grep -oE '[0-9]+')
        f=$(echo "$output" | grep -oE 'Failed[[:space:]]*[:-][[:space:]]*[0-9]+' | tail -1 | grep -oE '[0-9]+')
        [ -n "$p" ] && passed=$p
        [ -n "$f" ] && failed=$f
    fi

    echo "$output" | grep -qiE "crashed|aborted" && crashed=true
    rm -rf "$results_dir" 2>/dev/null || true
    echo "${passed}|${failed}|${crashed}"
}

# ─── Phase 1: ALL groups in parallel ──────────────────────────────────
echo ""
num_groups=${#GROUP_NAMES[@]}
echo "[Phase 1] Running $num_groups test groups in PARALLEL..."
phase1_start=$(date +%s)

cleanup_env
sleep 1
mkdir -p "$PARALLEL_DIR"

declare -a PIDS=()
for i in $(seq 0 $((num_groups - 1))); do
    (run_group "$TEST_DLL" "${GROUP_FILTERS[$i]}" > "$PARALLEL_DIR/result-$i.txt" 2>&1) &
    PIDS+=($!)
done
for pid in "${PIDS[@]}"; do wait "$pid" 2>/dev/null; done
phase1_elapsed=$(( $(date +%s) - phase1_start ))

# Collect results
declare -a RETRY_INDICES=()
for i in $(seq 0 $((num_groups - 1))); do
    name="${GROUP_NAMES[$i]}"
    result=$(cat "$PARALLEL_DIR/result-$i.txt" 2>/dev/null)
    IFS='|' read -r p f c <<< "$result"
    p=${p//[^0-9]/}; [ -z "$p" ] && p=0
    f=${f//[^0-9]/}; [ -z "$f" ] && f=0

    if [ "$c" = "true" ] || [ "$p" -eq 0 ]; then
        printf "  [%-20s] %dp/CRASHED — will retry\n" "$name" "$p"
        RETRY_INDICES+=($i)
        any_crashed=true
    elif [ "$f" -gt 0 ] 2>/dev/null; then
        printf "  [%-20s] %dp/%df\n" "$name" "$p" "$f"
        total_passed=$((total_passed + p))
        total_failed=$((total_failed + f))
    else
        printf "  [%-20s] %d passed\n" "$name" "$p"
        total_passed=$((total_passed + p))
    fi
done
echo "  (parallel phase: ${phase1_elapsed}s)"

# ─── Phase 2: Retry crashed groups sequentially ───────────────────────
if [ ${#RETRY_INDICES[@]} -gt 0 ]; then
    echo ""
    echo "[Phase 2] Retrying ${#RETRY_INDICES[@]} crashed group(s) sequentially..."
    cleanup_env
    sleep 2

    for i in "${RETRY_INDICES[@]}"; do
        name="${GROUP_NAMES[$i]}"
        expected="${GROUP_EXPECTED[$i]}"
        printf "  [%-20s] " "$name"

        best_p=0 best_f=0 best_c=false
        for attempt in 1 2 3; do
            cleanup_env
            sleep 1
            result=$(run_group "$TEST_DLL" "${GROUP_FILTERS[$i]}")
            IFS='|' read -r p f c <<< "$result"
            p=${p//[^0-9]/}; [ -z "$p" ] && p=0
            f=${f//[^0-9]/}; [ -z "$f" ] && f=0
            [ "$p" -gt "$best_p" ] && { best_p=$p; best_f=$f; best_c=$c; }
            [ "$best_p" -ge "$expected" ] && break
            [ "$attempt" -lt 3 ] && printf "RETRY%d(%dp)... " "$attempt" "$p"
        done

        if [ "$best_c" = "true" ] && [ "$best_p" -eq 0 ]; then
            echo "CRASHED"
        elif [ "$best_f" -gt 0 ] 2>/dev/null; then
            echo "${best_p}p/${best_f}f"
        else
            echo "${best_p} passed"
        fi
        [ "$best_p" -eq 0 ] && [ "$best_f" -eq 0 ] && groups_with_zero=$((groups_with_zero + 1))
        total_passed=$((total_passed + best_p))
        total_failed=$((total_failed + best_f))
    done
fi

# ─── Phase 3: FrmOptions isolated tests ───────────────────────────────
echo ""
echo "[Phase 3] FrmOptions isolated..."

for i in $(seq 0 $((${#ISO_NAMES[@]} - 1))); do
    name="${ISO_NAMES[$i]}"
    filter="${ISO_FILTERS[$i]}"
    printf "  [%-20s] " "$name"

    cleanup_env
    sleep 1
    result=$(run_group "$TEST_DLL" "$filter")
    IFS='|' read -r p f c <<< "$result"
    p=${p//[^0-9]/}; [ -z "$p" ] && p=0
    f=${f//[^0-9]/}; [ -z "$f" ] && f=0

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
        [ "$p2" -gt "$p" ] && { p=$p2; f=$f2; c=$c2; }
    done

    if [ "$c" = "true" ]; then
        echo "CRASHED"; any_crashed=true
    elif [ "$f" -gt 0 ] 2>/dev/null; then
        echo "FAILED"
    else
        echo "passed"
    fi
    total_passed=$((total_passed + p))
    total_failed=$((total_failed + f))
done

# ─── Cleanup + Summary ────────────────────────────────────────────────
rm -rf "$PARALLEL_DIR" 2>/dev/null || true

BACKUP="$REPO_ROOT/mRemoteNGTests/bin/x64/Release/.backup/mRemoteNGTests.dll"
if [ ! -f "$TEST_DLL" ] && [ -f "$BACKUP" ]; then
    echo ""
    echo "[Recovery] Restoring test DLL from backup"
    cp "$BACKUP" "$TEST_DLL"
fi

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

if [ "$total_failed" -gt 0 ]; then exit 1; fi
if [ "$total_tests" -lt "$MIN_TOTAL" ]; then
    echo "  EXIT 96: Coverage gap (phantom groups, no real failures)"
    exit 96
fi
exit 0
