#!/bin/bash
# Check for new upstream commits not yet tracked in upstream-tracking.json
# Usage: bash .project-roadmap/scripts/check-upstream.sh

set -e
cd "$(dirname "$0")/../.."

TRACKING=".project-roadmap/upstream-tracking.json"

echo "=== Fetching upstream ==="
git fetch upstream --quiet

echo ""
echo "=== New upstream commits (non-merge, since last check) ==="
LAST_CHECKED=$(python -c "import json; print(json.load(open('$TRACKING'))['_meta']['last_checked'])" 2>/dev/null || echo "2026-01-01")
echo "Last checked: $LAST_CHECKED"
echo ""

# Get tracked SHAs
TRACKED_SHAS=$(python -c "
import json
data = json.load(open('$TRACKING'))
for c in data.get('commits', []):
    print(c['sha'][:9])
" 2>/dev/null)

echo "--- Untracked commits ---"
FOUND=0
while IFS='|' read -r sha msg author date; do
    short="${sha:0:9}"
    if ! echo "$TRACKED_SHAS" | grep -q "$short"; then
        echo "  NEW  $short  $date  [$author]  $msg"
        FOUND=$((FOUND + 1))
    fi
done < <(git log upstream/v1.78.2-dev --format='%H|%s|%an|%ai' --no-merges --since="$LAST_CHECKED")

if [ "$FOUND" -eq 0 ]; then
    echo "  (none — all tracked)"
fi

echo ""
echo "--- Pending items (need review) ---"
python -c "
import json
data = json.load(open('$TRACKING'))
for c in data.get('commits', []):
    if c['status'] == 'pending':
        print(f\"  COMMIT  {c['sha'][:9]}  {c['message']}\")
for p in data.get('prs', []):
    if p['status'] == 'pending':
        print(f\"  PR #{p['number']}  {p['title']}\")
" 2>/dev/null

echo ""
echo "=== Summary ==="
python -c "
import json
from collections import Counter
data = json.load(open('$TRACKING'))
cs = Counter(c['status'] for c in data.get('commits', []))
ps = Counter(p['status'] for p in data.get('prs', []))
total_c = sum(cs.values())
total_p = sum(ps.values())
print(f'Commits: {total_c} tracked — ' + ', '.join(f'{v} {k}' for k,v in cs.most_common()))
print(f'PRs:     {total_p} tracked — ' + ', '.join(f'{v} {k}' for k,v in ps.most_common()))
" 2>/dev/null
