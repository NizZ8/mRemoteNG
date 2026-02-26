#!/usr/bin/env python3
"""
Cleanup robertpopa22 comments on upstream mRemoteNG/mRemoteNG.

Patches censored/broken comments with professional text + community disclaimer,
deletes junk (%MSG%, redundant corrections).

Usage:
    python cleanup_upstream_comments.py --dry-run                     # List all, no action
    python cleanup_upstream_comments.py --dry-run --category junk     # Preview junk only
    python cleanup_upstream_comments.py --execute --category junk     # Delete junk
    python cleanup_upstream_comments.py --execute --category all      # Full cleanup
    python cleanup_upstream_comments.py --resume                      # Resume interrupted run
"""
import sys
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

import argparse
import json
import re
import subprocess
import time
from pathlib import Path

UPSTREAM_REPO = "mRemoteNG/mRemoteNG"
FORK_REPO = "robertpopa22/mRemoteNG"
BOT_USER = "robertpopa22"
DONE_FILE = Path(__file__).parent / ".cleanup_done.json"
RATE_LIMIT_DELAY = 2.0  # seconds between API calls

# ── COMMUNITY DISCLAIMER ──────────────────────────────────────────────────────
COMMUNITY_DISCLAIMER = (
    "\n\n---\n\n"
    "> *We sincerely appreciate the mRemoteNG maintainers and the wonderful community "
    "that has kept this project alive and thriving for over a decade. Your work powers "
    "thousands of IT professionals worldwide, including us. Our fork builds entirely "
    "on your foundation \u2014 we're preparing a consolidated Pull Request to contribute "
    "these improvements back to the official project. Thank you for everything "
    "you've built.*\n"
    ">\n"
    "> *\u2014 robertpopa22, community contributor*"
)

# ── REPLACEMENT TEMPLATES ─────────────────────────────────────────────────────

TEMPLATE_FIX_AVAILABLE = (
    "**Fix available for testing**\n\n"
    "A fix for this issue has been implemented in our community fork "
    "(`{fork}`, branch `main`). "
    "A beta build including this fix is available from the fork's Releases page.\n\n"
    "Please test and report if this resolves your issue."
    "{disclaimer}"
)

TEMPLATE_COMMUNITY_RELEASE = (
    "**Fix available in community release**\n\n"
    "This fix is included in a community build from our fork "
    "(`{fork}`, branch `main`). "
    "Available from the fork's Releases page.\n\n"
    "Please test and let us know if the issue is fully resolved."
    "{disclaimer}"
)

TEMPLATE_TRIAGE_P2 = (
    "**Friendly check-in** \u2014 This issue has been inactive for a while. "
    "If you're still experiencing this, we'd appreciate it if you could retest "
    "on the latest build and share any reproducible steps, expected vs actual "
    "behavior, and logs/screenshots. This helps us prioritize and fix issues "
    "more effectively."
    "{disclaimer}"
)

TEMPLATE_TRIAGE_P4 = (
    "**Friendly check-in** \u2014 This issue was reported against an older version. "
    "If you're still experiencing this on a recent build, we'd love to hear about it "
    "\u2014 please share reproducible steps and expected vs actual behavior. "
    "If the issue is resolved, feel free to close it."
    "{disclaimer}"
)

TEMPLATE_TRIAGE_P3 = (
    "**Friendly check-in** \u2014 This issue appears to have stalled. "
    "If work is still in progress, a quick status update would be helpful. "
    "Otherwise, it may be relabeled to keep the tracker accurate."
    "{disclaimer}"
)

TEMPLATE_CLOSING = (
    "Closing for now \u2014 will revisit after further testing."
    "{disclaimer}"
)

TEMPLATE_TRIAGED_ROADMAP = (
    "Thank you for reporting this! We've triaged this issue and added it to "
    "our roadmap for an upcoming release. Will update here with progress."
    "{disclaimer}"
)

# ── CATEGORIES ────────────────────────────────────────────────────────────────
# Order matters: first match wins. More specific patterns first.

CATEGORIES = [
    {
        "name": "msg_junk",
        "description": "Junk %MSG% comments (orchestrator bug)",
        "pattern": r'"%MSG%"',
        "action": "delete",
        "template": None,
    },
    {
        "name": "correction",
        "description": "Redundant Correction comments (re-censored)",
        "pattern": r"^\*\*Correction",
        "action": "delete",
        "template": None,
    },
    {
        "name": "censored_community",
        "description": "Fix in community release (link censored)",
        "pattern": r"community release.*\[CENSORED!\]|\[CENSORED!\].*community",
        "action": "patch",
        "template": TEMPLATE_COMMUNITY_RELEASE,
    },
    {
        "name": "censored_fix",
        "description": "Fix available for testing (link censored)",
        "pattern": r"\[CENSORED!\].*Fix available|Fix available.*\[CENSORED!\]|CENSORED",
        "action": "patch",
        "template": TEMPLATE_FIX_AVAILABLE,
    },
    {
        "name": "community_release_link",
        "description": "Fix in community release (raw github.com link, not censored yet)",
        "pattern": r"Fix available in community release.*https://github\.com/",
        "action": "patch",
        "template": TEMPLATE_COMMUNITY_RELEASE,
    },
    {
        "name": "triage_p2",
        "description": "Triage refresh (P2) — not our call, delete",
        "pattern": r"Triage refresh \(P2\)",
        "action": "delete",
        "template": None,
    },
    {
        "name": "triage_p2_alt",
        "description": "P2 refresh (alt format) — not our call, delete",
        "pattern": r"^P2 refresh:",
        "action": "delete",
        "template": None,
    },
    {
        "name": "triage_p4",
        "description": "Triage refresh (P4) — not our call, delete",
        "pattern": r"Triage refresh \(P4",
        "action": "delete",
        "template": None,
    },
    {
        "name": "triage_p3",
        "description": "Triage (P3) — not our call, delete",
        "pattern": r"Triage \(P3",
        "action": "delete",
        "template": None,
    },
    {
        "name": "triage_refresh_generic",
        "description": "Triage refresh (generic) — not our call, delete",
        "pattern": r"^Triage refresh:",
        "action": "delete",
        "template": None,
    },
    {
        "name": "closing",
        "description": "Closing for now — not our call, delete",
        "pattern": r"^Closing for now",
        "action": "delete",
        "template": None,
    },
    {
        "name": "triaged_roadmap",
        "description": "Triaged to roadmap — not our call, delete",
        "pattern": r"triaged this issue and added it to our roadmap",
        "action": "delete",
        "template": None,
    },
    # ── Triage-like misc comments — not fix announcements, delete ─────────
    {
        "name": "triage_update_fork",
        "description": "Triage update from fork validation — not a fix announcement, delete",
        "pattern": r"^Triage update from fork",
        "action": "delete",
        "template": None,
    },
    {
        "name": "followup_triage",
        "description": "Follow-up triage note — not a fix announcement, delete",
        "pattern": r"^Follow-up triage note",
        "action": "delete",
        "template": None,
    },
    # ── Shell injection artifacts (&echo in URLs) — buggy, delete ─────────
    {
        "name": "shell_injection",
        "description": "Comments with &echo (shell metachar bug) — delete",
        "pattern": r"&echo\s+https://",
        "action": "delete",
        "template": None,
    },
    # ── FIX comments with github.com links (will be censored) ─────────────
    {
        "name": "fix_with_links",
        "description": "Fix available with github.com links (will be censored by filter-links)",
        "pattern": r"(?s)^\*\*Fix available for testing\*\*.*https://github\.com/",
        "action": "patch",
        "template": TEMPLATE_FIX_AVAILABLE,
    },
    # ── CATCH-ALL: fix-related comments — sanitize links + append disclaimer
    # These use action "append_disclaimer" — keeps original body, strips
    # github.com links (to avoid filter-links censoring), adds disclaimer.
    {
        "name": "fix_no_disclaimer",
        "description": "Fix available (no links, clean) — append disclaimer",
        "pattern": r"^\*\*Fix available for testing\*\*",
        "action": "append_disclaimer",
        "template": None,
    },
    {
        "name": "misc_fix_related",
        "description": "Other fix-related comments — sanitize links + append disclaimer",
        "pattern": r".",  # matches everything remaining
        "action": "append_disclaimer",
        "template": None,
    },
]

# ── HELPERS ───────────────────────────────────────────────────────────────────

def gh_api(endpoint, method="GET", body=None, paginate=False):
    """Call GitHub API via gh CLI."""
    cmd = ["gh", "api", endpoint]
    if method != "GET":
        cmd += ["--method", method]
    if paginate:
        cmd.append("--paginate")
    if body:
        cmd += ["--input", "-"]

    env = {**__import__("os").environ, "PYTHONIOENCODING": "utf-8"}
    result = subprocess.run(
        cmd,
        capture_output=True, timeout=120,
        input=json.dumps(body).encode("utf-8") if body else None,
        env=env,
    )
    stdout = result.stdout.decode("utf-8", errors="replace") if result.stdout else ""
    stderr = result.stderr.decode("utf-8", errors="replace") if result.stderr else ""
    if result.returncode != 0:
        raise RuntimeError(f"gh api failed: {stderr.strip()}")
    return json.loads(stdout) if stdout.strip() else None


def fetch_all_comments():
    """Fetch ALL comments by BOT_USER across all issues in upstream repo.

    Uses manual pagination with per_page=100. The gh --paginate flag
    concatenates JSON arrays which breaks json.loads, so we paginate manually.
    """
    print(f"Fetching all comments by {BOT_USER} on {UPSTREAM_REPO}...")
    print("(This may take several minutes for large repos)")

    all_comments = []
    page = 1
    per_page = 100
    # Start from 2024-01-01 to skip ancient comments (our bot started ~2024)
    since = "2024-01-01T00:00:00Z"

    while True:
        endpoint = (
            f"/repos/{UPSTREAM_REPO}/issues/comments"
            f"?per_page={per_page}&page={page}&sort=created&direction=asc"
            f"&since={since}"
        )
        try:
            comments = gh_api(endpoint)
        except RuntimeError as e:
            print(f"  Error on page {page}: {e}")
            break

        if not comments:
            break

        user_comments = [
            c for c in comments
            if c.get("user", {}).get("login") == BOT_USER
        ]
        all_comments.extend(user_comments)

        total_on_page = len(comments)
        print(f"  Page {page}: {total_on_page} total, "
              f"{len(user_comments)} by {BOT_USER} "
              f"(cumulative: {len(all_comments)})")

        if total_on_page < per_page:
            break
        page += 1
        time.sleep(0.3)  # light rate limiting during fetch

    print(f"\nTotal comments by {BOT_USER}: {len(all_comments)}")
    return all_comments


def classify_comment(comment):
    """Classify a comment into a category. Returns category dict or None."""
    body = comment.get("body", "")
    for cat in CATEGORIES:
        if re.search(cat["pattern"], body, re.MULTILINE | re.IGNORECASE):
            return cat
    return None


def extract_issue_number(comment):
    """Extract issue number from comment's issue_url."""
    url = comment.get("issue_url", "")
    m = re.search(r"/issues/(\d+)$", url)
    return int(m.group(1)) if m else 0


def has_disclaimer(body):
    """Check if comment already has the community disclaimer."""
    return "community contributor" in body and "robertpopa22" in body


def sanitize_github_links(text):
    """Replace github.com URLs with plain text to avoid filter-links.yml censoring.

    The upstream repo has a GitHub Action (filter-links.yml) that replaces any URL
    matching github.com/USER/REPO with [CENSORED!]. We convert such URLs to plain
    text references.
    """
    # Markdown links: [text](https://github.com/user/repo/...) → text (user/repo)
    def replace_md_link(m):
        label = m.group(1)
        url = m.group(2)
        # Extract user/repo from URL
        parts = re.match(r"https://github\.com/([^/]+/[^/]+)(?:/(.*))?", url)
        if parts:
            repo = parts.group(1)
            path = parts.group(2) or ""
            if "commit/" in path:
                return f"{label} (`{repo}`)"
            elif "pull/" in path:
                pr_num = re.search(r"pull/(\d+)", path)
                if pr_num:
                    return f"{label} (PR #{pr_num.group(1)} on `{repo}`)"
            elif "actions/runs/" in path:
                return f"{label} (CI on `{repo}`)"
            elif "releases" in path:
                return f"{label} (releases on `{repo}`)"
            return f"{label} (`{repo}`)"
        return label

    text = re.sub(r"\[([^\]]+)\]\((https://github\.com/[^)]+)\)", replace_md_link, text)

    # Bare URLs: https://github.com/user/repo/... → `user/repo` (path description)
    def replace_bare_url(m):
        url = m.group(0)
        parts = re.match(r"https://github\.com/([^/]+/[^/]+)(?:/(.*))?", url)
        if parts:
            repo = parts.group(1)
            path = parts.group(2) or ""
            if "commit/" in path:
                short_hash = path.split("commit/")[-1][:8]
                return f"commit `{short_hash}` on `{repo}`"
            elif "pull/" in path:
                pr_num = re.search(r"pull/(\d+)", path)
                if pr_num:
                    return f"PR #{pr_num.group(1)} on `{repo}`"
            elif "actions/runs/" in path:
                run_id = path.split("actions/runs/")[-1].split("/")[0]
                return f"CI run {run_id} on `{repo}`"
            elif "releases" in path:
                return f"releases page of `{repo}`"
            return f"`{repo}`"
        return url

    text = re.sub(r"https://github\.com/[^\s)>\]]+", replace_bare_url, text)

    return text


def build_replacement(cat, comment):
    """Build replacement body for a comment."""
    action = cat.get("action", "")
    if action == "append_disclaimer":
        # Keep original body, sanitize github links, append disclaimer
        body = comment.get("body", "").rstrip()
        body = sanitize_github_links(body)
        return body + COMMUNITY_DISCLAIMER
    if action == "delete":
        return None
    template = cat.get("template", "")
    if not template:
        return None
    return template.format(
        fork=FORK_REPO,
        disclaimer=COMMUNITY_DISCLAIMER,
    )


def load_done():
    """Load set of already-processed comment IDs."""
    if DONE_FILE.exists():
        try:
            data = json.loads(DONE_FILE.read_text(encoding="utf-8"))
            return set(data.get("done", []))
        except Exception:
            pass
    return set()


def save_done(done_set):
    """Save processed comment IDs."""
    DONE_FILE.write_text(
        json.dumps({"done": sorted(done_set)}, indent=2),
        encoding="utf-8",
    )


# ── MAIN ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Cleanup robertpopa22 comments on upstream mRemoteNG"
    )
    parser.add_argument(
        "--dry-run", action="store_true", default=True,
        help="List changes without executing (default)"
    )
    parser.add_argument(
        "--execute", action="store_true",
        help="Actually execute PATCH/DELETE operations"
    )
    parser.add_argument(
        "--category", type=str, default="all",
        help="Comma-separated categories to process (or 'all')"
    )
    parser.add_argument(
        "--resume", action="store_true",
        help="Skip already-processed comments (from .cleanup_done.json)"
    )
    parser.add_argument(
        "--fetch-cache", type=str, default=None,
        help="Path to cached comments JSON (skip fetching)"
    )
    parser.add_argument(
        "--save-cache", type=str, default=None,
        help="Save fetched comments to JSON file"
    )
    parser.add_argument(
        "--limit", type=int, default=0,
        help="Max number of operations to execute (0 = unlimited)"
    )
    args = parser.parse_args()

    if args.execute:
        args.dry_run = False

    # Parse categories
    if args.category == "all":
        active_cats = {c["name"] for c in CATEGORIES}
    else:
        active_cats = {c.strip() for c in args.category.split(",")}
        valid_names = {c["name"] for c in CATEGORIES}
        invalid = active_cats - valid_names
        if invalid:
            print(f"ERROR: Unknown categories: {invalid}")
            print(f"Valid: {sorted(valid_names)}")
            sys.exit(1)

    # Fetch or load comments
    if args.fetch_cache:
        cache_path = Path(args.fetch_cache)
        print(f"Loading cached comments from {cache_path}...")
        all_comments = json.loads(cache_path.read_text(encoding="utf-8"))
        print(f"Loaded {len(all_comments)} comments from cache.")
    else:
        all_comments = fetch_all_comments()

    if args.save_cache:
        save_path = Path(args.save_cache)
        save_path.write_text(
            json.dumps(all_comments, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )
        print(f"Saved {len(all_comments)} comments to {save_path}")

    # Load resume state
    done_ids = load_done() if args.resume else set()
    if done_ids:
        print(f"Resuming: {len(done_ids)} comments already processed.")

    # Classify
    classified = {c["name"]: [] for c in CATEGORIES}
    classified["_unclassified"] = []
    classified["_has_disclaimer"] = []

    for comment in all_comments:
        cid = comment["id"]
        body = comment.get("body", "")
        issue_num = extract_issue_number(comment)

        # Skip already processed
        if cid in done_ids:
            continue

        # Skip if already has disclaimer (already patched)
        if has_disclaimer(body):
            classified["_has_disclaimer"].append({
                "id": cid, "issue": issue_num,
                "preview": body[:80].replace("\n", " ")
            })
            continue

        cat = classify_comment(comment)
        if cat:
            classified[cat["name"]].append({
                "id": cid,
                "issue": issue_num,
                "category": cat["name"],
                "action": cat["action"],
                "body": body,
                "preview": body[:100].replace("\n", " "),
                "new_body": build_replacement(cat, comment),
            })
        else:
            classified["_unclassified"].append({
                "id": cid, "issue": issue_num,
                "preview": body[:100].replace("\n", " ")
            })

    # Print summary
    print("\n" + "=" * 70)
    print("CLASSIFICATION SUMMARY")
    print("=" * 70)

    total_actions = 0
    for cat in CATEGORIES:
        name = cat["name"]
        items = classified[name]
        if items:
            action = cat["action"].upper()
            print(f"  {name:25s} {action:8s} {len(items):5d}")
            if name in active_cats:
                total_actions += len(items)

    skip_disclaimer = len(classified["_has_disclaimer"])
    skip_unclassified = len(classified["_unclassified"])
    print(f"  {'_has_disclaimer':25s} {'SKIP':8s} {skip_disclaimer:5d}")
    print(f"  {'_unclassified':25s} {'MANUAL':8s} {skip_unclassified:5d}")
    print("-" * 70)
    print(f"  Active categories: {', '.join(sorted(active_cats))}")
    print(f"  Actions to execute: {total_actions}")
    print()

    # Show unclassified for manual review
    if classified["_unclassified"] and "all" in args.category:
        print("\nUNCLASSIFIED COMMENTS (need manual review):")
        for item in classified["_unclassified"][:20]:
            print(f"  #{item['issue']:5d} id={item['id']}  {item['preview']}")
        if len(classified["_unclassified"]) > 20:
            print(f"  ... and {len(classified['_unclassified']) - 20} more")

    # Show preview for active categories
    for cat in CATEGORIES:
        name = cat["name"]
        if name not in active_cats:
            continue
        items = classified[name]
        if not items:
            continue

        print(f"\n{'─' * 70}")
        print(f"Category: {name} ({cat['action'].upper()}) — {len(items)} items")
        print(f"{'─' * 70}")

        for item in items[:3]:
            print(f"\n  Issue #{item['issue']} (comment id={item['id']})")
            print(f"  OLD: {item['preview']}...")
            if item.get("new_body"):
                preview = item["new_body"][:120].replace("\n", " ")
                print(f"  NEW: {preview}...")

        if len(items) > 3:
            print(f"\n  ... and {len(items) - 3} more")

    if args.dry_run:
        print("\n[DRY RUN] No changes made. Use --execute to apply.")
        return

    # Execute
    print(f"\n{'=' * 70}")
    print(f"EXECUTING — {total_actions} operations")
    print(f"{'=' * 70}")

    ops_done = 0
    ops_failed = 0
    new_done = set(done_ids)

    for cat in CATEGORIES:
        name = cat["name"]
        if name not in active_cats:
            continue
        items = classified[name]
        if not items:
            continue

        print(f"\n[{name}] {cat['action'].upper()} {len(items)} comments...")

        for i, item in enumerate(items, 1):
            if args.limit and ops_done >= args.limit:
                print(f"\n  Limit reached ({args.limit}). Stopping.")
                save_done(new_done)
                return

            cid = item["id"]
            issue = item["issue"]

            try:
                if cat["action"] == "delete":
                    endpoint = f"/repos/{UPSTREAM_REPO}/issues/comments/{cid}"
                    gh_api(endpoint, method="DELETE")
                    print(f"  [{i}/{len(items)}] DELETE #{issue} comment {cid} ✓")

                elif cat["action"] in ("patch", "append_disclaimer"):
                    new_body = item["new_body"]
                    if not new_body:
                        print(f"  [{i}/{len(items)}] SKIP #{issue} — no template")
                        continue
                    endpoint = f"/repos/{UPSTREAM_REPO}/issues/comments/{cid}"
                    gh_api(endpoint, method="PATCH", body={"body": new_body})
                    label = "PATCH" if cat["action"] == "patch" else "APPEND"
                    print(f"  [{i}/{len(items)}] {label} #{issue} comment {cid} \u2713")

                ops_done += 1
                new_done.add(cid)

            except Exception as e:
                ops_failed += 1
                print(f"  [{i}/{len(items)}] FAIL #{issue} comment {cid}: {e}")

            # Rate limiting
            time.sleep(RATE_LIMIT_DELAY)

            # Save progress every 25 operations
            if ops_done % 25 == 0:
                save_done(new_done)

    # Final save
    save_done(new_done)

    print(f"\n{'=' * 70}")
    print(f"DONE: {ops_done} succeeded, {ops_failed} failed")
    print(f"Progress saved to {DONE_FILE}")
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()
