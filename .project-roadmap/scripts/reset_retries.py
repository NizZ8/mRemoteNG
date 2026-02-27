#!/usr/bin/env python3
"""Reset 153 triaged issues for re-implementation with combined triage+plan+implement prompt.

Actions:
1. Delete all chain-context files (implement + triage) — resets attempt counters
2. Set impl_failed=True on all triaged issues (so orchestrator picks them up for retry)
3. Clean "Needs human" from notes (leftover from previous max-retry skips)

Usage:
    python reset_retries.py          # dry-run (default)
    python reset_retries.py --execute  # actually do it
"""

import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

import json
import os
import glob
from pathlib import Path

REPO_ROOT = Path(r"D:\github\mRemoteNG")
CHAIN_CONTEXT_DIR = REPO_ROOT / ".project-roadmap" / "scripts" / "chain-context"
ISSUES_DB_DIR = REPO_ROOT / ".project-roadmap" / "issues-db" / "upstream"


def main():
    execute = "--execute" in sys.argv

    # 1. Delete chain-context files
    deleted = 0
    if CHAIN_CONTEXT_DIR.exists():
        for f in CHAIN_CONTEXT_DIR.iterdir():
            if f.name.startswith("_"):
                continue  # keep _timeout_history.json etc.
            if execute:
                f.unlink()
            deleted += 1
    print(f"{'Deleted' if execute else 'Would delete'} {deleted} chain-context files")

    # 2. Update triaged issues
    updated = 0
    for fpath in sorted(ISSUES_DB_DIR.glob("*.json")):
        if fpath.name.startswith("_"):
            continue
        try:
            data = json.loads(fpath.read_text(encoding="utf-8-sig"))
        except Exception:
            continue

        if data.get("our_status") != "triaged":
            continue

        notes = data.get("notes", "") or ""

        # Already impl_failed=True and no "Needs human" → skip
        if data.get("impl_failed") is True and "Needs human" not in notes:
            updated += 1  # count but don't re-write
            continue

        changed = False

        # Set impl_failed=True
        if not data.get("impl_failed"):
            data["impl_failed"] = True
            changed = True

        # Clean "Needs human" from notes
        if "Needs human" in notes:
            # Remove the "Needs human intervention..." line
            lines = notes.split("\n")
            lines = [l for l in lines if "Needs human" not in l]
            data["notes"] = "\n".join(lines).strip()
            changed = True

        # Clean "Skipped:" status text
        status_text = data.get("status_text", "")
        if status_text and "Skipped:" in status_text:
            data["status_text"] = ""
            changed = True

        if changed:
            if execute:
                fpath.write_text(json.dumps(data, indent=2, ensure_ascii=False),
                                 encoding="utf-8")
            updated += 1

    print(f"{'Updated' if execute else 'Would update'} {updated} triaged issues (impl_failed=True)")

    if not execute:
        print("\nDry run. Use --execute to apply changes.")


if __name__ == "__main__":
    main()
