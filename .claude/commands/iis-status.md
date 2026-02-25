# /iis-status — Show IIS Orchestrator Status

Show the current status of the IIS Orchestrator (running or last completed run),
plus overall project progress and new issues.

## What to do

### 1. Current session status
Read the status file and last 30 lines of the log:
```
D:\github\mRemoteNG\.project-roadmap\scripts\orchestrator-status.json
D:\github\mRemoteNG\.project-roadmap\scripts\orchestrator.log
```

Check if orchestrator processes are alive AND identify each one:
```bash
powershell.exe -NoProfile -Command 'Get-Process python* -ErrorAction SilentlyContinue | ForEach-Object { $p = $_; $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue).CommandLine; [PSCustomObject]@{PID=$p.Id; Start=$p.StartTime.ToString("HH:mm:ss"); CPU=[math]::Round($p.CPU,1); "Mem(MB)"=[math]::Round($p.WorkingSet64/1MB,0); CommandLine=$cmd} } | Format-Table PID, Start, CPU, "Mem(MB)", CommandLine -AutoSize -Wrap'
```

Analyze the process list and identify each process role:
- **Supervisor**: runs `orchestrator_supervisor.py` — should be exactly 1
- **Orchestrator**: runs `iis_orchestrator.py` — should be exactly 1
- **Claude agent**: runs `claude` — spawned by orchestrator for current issue
- **Build/Test worker**: runs `pwsh` or `dotnet` — spawned during build/test phase
- **Orphan**: any python process that doesn't match the above — flag as WARNING

Flag problems:
- Multiple supervisors = orphan from previous session, kill the older one
- Orchestrator without supervisor = unmanaged, could hang forever
- Supervisor without orchestrator = supervisor may be about to restart it (OK if brief)
- Stale processes (running 2+ hours with no status update) = likely hung

Present session summary:
- **Running state**: Is the orchestrator currently active?
- **Current phase**: issues / warnings / done
- **Current task**: What issue is being processed right now
- **Issues**: synced, triaged, implemented, failed, skipped (by reason)
- **Warnings**: start count -> current count (fixed count, % improvement)
- **Commits**: List of commits made this session (hash + message)
- **Errors**: Any errors encountered
- **Cost**: Token usage and USD cost
- **Duration**: How long the session has been running

### 2. Overall project progress (ALL sessions combined)
Run these commands to gather cumulative stats:

```bash
cd D:/github/mRemoteNG && python -c "
import sys, os, json, subprocess, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

db_dir = '.project-roadmap/issues-db/upstream'

# 1. Count issues by our_status from DB
status_counts = {}
total_db = 0
for f in os.listdir(db_dir):
    if not f.endswith('.json'): continue
    total_db += 1
    try:
        data = json.load(open(os.path.join(db_dir, f), encoding='utf-8'))
        s = data.get('our_status', 'unknown')
        status_counts[s] = status_counts.get(s, 0) + 1
    except: pass

# 2. Count unique issues with fix commits (ground truth)
# Search both formats: fix(#N) and Fix #N:
commit_issues = set()
for grep_pat in ['^fix(#', '^Fix #']:
    result = subprocess.run(['git', 'log', '--oneline', f'--grep={grep_pat}'], capture_output=True, text=True)
    for line in result.stdout.strip().split('\n'):
        if not line: continue
        # Match fix(#123) or Fix #123: — require exact issue number boundary
        for m in re.finditer(r'(?:fix\(#|Fix #|fix #)(\d+)', line):
            num = int(m.group(1))
            # Exclude false substring matches (e.g. #2274 matching #274)
            # by checking the number exists in the DB
            padded = f'{num:04d}'
            if os.path.exists(os.path.join(db_dir, f'{padded}.json')):
                commit_issues.add(num)

# 3. Cross-reference: issues with commits vs DB status
has_commit_by_status = {}
for inum in commit_issues:
    padded = f'{inum:04d}'
    fp = os.path.join(db_dir, f'{padded}.json')
    if os.path.exists(fp):
        try:
            data = json.load(open(fp, encoding='utf-8'))
            s = data.get('our_status', 'unknown')
            has_commit_by_status[s] = has_commit_by_status.get(s, 0) + 1
        except: pass

# 4. Calculate accurate numbers
issues_with_fixes = len(commit_issues)
closed_no_code = status_counts.get('wontfix', 0) + status_counts.get('duplicate', 0)
# Issues truly resolved = unique issues with fix commits + closed without code
truly_resolved = issues_with_fixes + closed_no_code
# Subtract any wontfix/duplicate that also have commits (avoid double count)
truly_resolved -= has_commit_by_status.get('wontfix', 0) + has_commit_by_status.get('duplicate', 0)

pct = int(truly_resolved / total_db * 100) if total_db else 0
bar_filled = int(pct / 100 * 30)
bar = chr(9608) * bar_filled + chr(9617) * (30 - bar_filled)

# 5. Remaining issues (not resolved)
remaining = total_db - truly_resolved
remaining_testing = status_counts.get('testing', 0)
remaining_triaged = status_counts.get('triaged', 0) - has_commit_by_status.get('triaged', 0)
remaining_new = status_counts.get('new', 0)
remaining_needs_human = status_counts.get('needs_human', 0)

# Output for Claude to format
print(f'TOTAL_DB={total_db}')
print(f'ISSUES_WITH_FIXES={issues_with_fixes}')
print(f'CLOSED_NO_CODE={closed_no_code}')
print(f'TRULY_RESOLVED={truly_resolved}')
print(f'REMAINING={remaining}')
print(f'PCT={pct}')
print(f'BAR=[{bar}]')
for s in ['released','testing','triaged','new','wontfix','duplicate','needs_human','impl_failed']:
    print(f'STATUS_{s}={status_counts.get(s, 0)}')
# Show status tracking gap
gap = has_commit_by_status.get('triaged', 0)
print(f'TRIAGED_WITH_COMMITS={gap}')
# Show calculation breakdown for verification
print()
print('--- Calculation ---')
print(f'  Issues with fix commits (unique): {issues_with_fixes}')
print(f'    of which: {has_commit_by_status}')
print(f'  Closed without code (wontfix+duplicate): {closed_no_code}')
print(f'  Double-counted (wontfix/dup with commits): -{has_commit_by_status.get(\"wontfix\", 0) + has_commit_by_status.get(\"duplicate\", 0)}')
print(f'  = Truly resolved: {issues_with_fixes} + {closed_no_code} - {has_commit_by_status.get(\"wontfix\", 0) + has_commit_by_status.get(\"duplicate\", 0)} = {truly_resolved}')
print(f'  = Remaining: {total_db} - {truly_resolved} = {remaining}')
print(f'    Testing (unverified): {remaining_testing}')
print(f'    Triaged (no commit):  {remaining_triaged}')
print(f'    New (not started):    {remaining_new}')
print(f'    Needs human:          {remaining_needs_human}')
"
```

Present the progress using the script output. Key metrics:
- **Issues with fix commits**: ground truth from git log, counting unique issue numbers
- **Closed without code**: wontfix + duplicate (no fix commit needed)
- **Truly resolved**: issues with fix commits + closed without code (deduplicated)
- **Remaining**: total - truly resolved, broken down by category
- **Calculation**: always show the math so the user can verify
- **Status tracking gap**: issues marked "triaged" that actually have fix commits
  (flag this as a warning if > 0)

### 3. New issues (last 7 days)
Check for recently created issues on both upstream and fork:

```bash
# Upstream new issues (last 7 days)
gh issue list --repo mRemoteNG/mRemoteNG --state open --json number,title,createdAt,labels --limit 10 | python -c "
import json, sys
from datetime import datetime, timedelta
cutoff = datetime.utcnow() - timedelta(days=7)
issues = json.load(sys.stdin)
recent = [i for i in issues if datetime.fromisoformat(i['createdAt'].rstrip('Z')) > cutoff]
for i in recent:
    labels = ', '.join(l['name'] for l in i.get('labels', []))
    lbl = f' [{labels}]' if labels else ''
    print(f'  #{i[\"number\"]} {i[\"title\"]}{lbl}')
if not recent:
    print('  (none)')
"

# Fork new issues (last 7 days)
gh issue list --repo robertpopa22/mRemoteNG --state open --json number,title,createdAt --limit 10 | python -c "
import json, sys
from datetime import datetime, timedelta
cutoff = datetime.utcnow() - timedelta(days=7)
issues = json.load(sys.stdin)
recent = [i for i in issues if datetime.fromisoformat(i['createdAt'].rstrip('Z')) > cutoff]
for i in recent:
    print(f'  #{i[\"number\"]} {i[\"title\"]}')
if not recent:
    print('  (none)')
"
```

### 4. If no status file exists
Inform the user that no orchestrator run has been recorded yet, but still show
overall progress and new issues sections.

## Format

Present the status in a clean, readable format. Example:

```
IIS Orchestrator Status: RUNNING                          Report: 2026-02-25 10:55
Phase: issues | Task: Claude fixing #730 (Remote printing) — Sonnet

--- Processes --------------------------------------------------
  PID   Start     CPU  Mem   Role
  35156 08:39:21  17.9  17M  Supervisor (orchestrator_supervisor.py)
  30352 08:39:25   6.8  25M  Orchestrator (iis_orchestrator.py --force)
  25260 08:40:12  22.1  16M  WARNING: 2nd Supervisor (orphan?)
  Health: 2 supervisors detected — older one may be orphan from nohup

Issues (this session): 217 synced | 12/217 (6%)
  Implemented: 9 | Failed: 0 | Commented: 9

Commits (this session): 9
  [OK] 053888b fix(#1986): Can't connection to sql database
  [OK] c1f3877 fix(#343): Minimize tabs on connect
  ...

Errors: 3
  [08:51] #1905 — all agents failed
  [09:40] #551  — all agents failed

Cost: $22.97 | Duration: 02:16

--- Overall Progress (all sessions) ----------------------------
Issues DB: 839 total
  DB Status:  Released: 505 | Testing: 15 | Wontfix: 56 | Duplicate: 24
              Triaged: 86 | New: 149 | Needs Human: 4

  Verified (cross-referenced with git):
    Issues with fix commits: 475 unique
    Closed without code:      80 (wontfix + duplicate)
    Truly resolved:          548/839
    [███████████████████░░░░░░░░░░░] 65%

  Remaining: 291
    Testing (unverified):  15
    Triaged (no commit):   85
    New (not started):    149
    Needs human:            4

  Calculation: 475 + 80 - 7 (double-counted) = 548 resolved
               839 - 548 = 291 remaining

Tests: 2925 passing

--- New Issues (last 7 days) -----------------------------------
Upstream (mRemoteNG/mRemoteNG):
  #3173 Possible command injection via Process.Start (2026-02-24)
  #3170 Opening Command sent too soon during SSH login (2026-02-24)
  #3167 mRemoteNG 1.78.2 requires .NET 9.0 (2026-02-23)
  #3166 Jump-host tabs wrong resolution after RDP reconnect (2026-02-23)

Fork (robertpopa22/mRemoteNG):
  #19 [No application window] mRemoteNG 1.81.0-beta.3
```
