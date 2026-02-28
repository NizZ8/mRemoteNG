<p align="center">
  <img width="450" src="https://github.com/mRemoteNG/mRemoteNG/blob/mRemoteNGProjectFiles/Header_dark.png">
</p>

# mRemoteNG — Community Edition

<blockquote>

**This fork is alive.** We love mRemoteNG and we're committed to keeping it moving forward. This Community Edition ships regular releases with security patches, bug fixes, and long-requested features — backed by proper CI, automated tests, and builds for x64, x86, and ARM64.

Full transparency: this project is built by humans and AI working together. We believe that's the future of open source.

*— Robert & contributors (human + AI)*

</blockquote>

<p align="center">
  <a href="https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.81.0-beta.5">
    <img alt="Beta" src="https://img.shields.io/badge/beta-v1.81.0--beta.5-orange?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/tree/main">
    <img alt="Next" src="https://img.shields.io/badge/next-v1.81.0--beta.6-blue?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/actions">
    <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/pr_validation.yml?style=for-the-badge&label=CI">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/releases/tag/nightly">
    <img alt="Nightly" src="https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/nightly.yml?style=for-the-badge&label=Nightly&color=blueviolet">
  </a>
  <a href="https://sonarcloud.io/project/overview?id=robertpopa22_mRemoteNG">
    <img alt="SonarCloud" src="https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/sonarcloud.yml?style=for-the-badge&label=Sonar">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/security/code-scanning">
    <img alt="CodeQL" src="https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/codeql.yml?style=for-the-badge&label=CodeQL">
  </a>
  <a href="COPYING.TXT">
    <img alt="License" src="https://img.shields.io/badge/license-GPL--2.0-green?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/releases">
    <img alt="Total Downloads" src="https://img.shields.io/badge/total%20downloads-831-green?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/stargazers">
    <img alt="Stars" src="https://img.shields.io/github/stars/robertpopa22/mRemoteNG?style=for-the-badge&color=yellow">
  </a>
</p>

---

## Downloads

| Channel | Version | What you get |
|---------|---------|--------------|
| **[Nightly](https://github.com/robertpopa22/mRemoteNG/releases/tag/nightly)** | Latest from `main` | Auto-built on every push, fully tested. x64 framework-dependent only. |
| **[Beta](https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.81.0-beta.5)** | v1.81.0-beta.5 | High-velocity builds — .NET 10, security hardening, experimental features. Promoted to Stable after 5+ iterations. |
| **[Stable](https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.76.20)** | v1.76.20 | Production-ready. Recommended for most users. |

### Beta download matrix

| Variant | x64 | x86 | ARM64 |
|---------|-----|-----|-------|
| Framework-dependent (~21MB) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-x64.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-x86.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-arm64.zip) |
| Self-contained (~108-116MB) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-win-x64-SelfContained.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-win-x86-SelfContained.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.5/mRemoteNG-v1.81.0-beta.5-win-arm64-SelfContained.zip) |

**Framework-dependent** requires [.NET Desktop Runtime 10.0](https://dotnet.microsoft.com/download/dotnet/10.0). **Self-contained** includes the .NET runtime — no prerequisites.

---

## Features

16 protocols supported: **RDP**, **VNC**, **SSH**, **Telnet**, **HTTP/HTTPS**, **rlogin**, **Raw Socket**, **PowerShell Remoting**, **AnyDesk**, **VMRC** (VMware), **MSRA** (Remote Assistance), **OpenSSH** (native Windows), **Winbox** (MikroTik), **WSL**, **Terminal**, **Serial** (COM port).

**Security:** PBKDF2 600K iterations, HTTPS-only vaults, SSH key wipe, AnyDesk command injection prevention, LDAP sanitization, 4 CodeQL alerts fixed.

**Enterprise:** Self-contained builds (zero prerequisites), ADMX/ADML Group Policy templates, connection audit logging, JSON export, protocol/tag filtering.

**Quality:** 5,967 automated tests, 4-level code quality (Roslynator + Meziantou + SonarCloud + CodeQL), x64/x86/ARM64.

For detailed usage, refer to the [Documentation](https://mremoteng.readthedocs.io/en/latest/).

---

## How We Build This — A Scientific Approach to Hybrid AI+Human Development

### The Hypothesis We Tested

Can an autonomous AI orchestrator resolve a backlog of 838 issues on a legacy WinForms/.NET 10 project?

**Short answer:** Yes, but not the way we expected. The journey from "let AI fix everything" to "a self-healing supervisor coordinating AI agents with human oversight" took four architectural generations, a 31-hour disaster, and approximately $320 in API costs.

### Architecture Evolution — Four Generations of Failure and Learning

#### Gen 1: Brute Force (early February)

Claude Sonnet on everything. Manual triage, manual implementation, manual commit.

**Result:** 26 bug fixes (v1.79.0), 2,179 tests passing, but slow — days of human work per release. Each fix required a human to read the issue, decide what to do, prompt the AI, review the code, run the build, run the tests, commit, and post a comment. The AI was a code-writing accelerator, not an autonomous agent.

#### Gen 2: Multi-Agent Orchestra (Feb 9–16)

Three AI agents coordinated by a Python orchestrator:

| Agent | Strengths | Fatal Flaws |
|-------|-----------|-------------|
| **Codex** (OpenAI `gpt-5.3-codex-spark`) | By far the fastest and most reliable for code interpretation and implementation. 15-25s triage, cheap, high success rate on single-file fixes | Linux sandbox on Windows — can't run MSBuild, PowerShell, or COM references. `--full-auto` maps to `sandbox: read-only` on Windows. Only workaround: `--dangerously-bypass-approvals-and-sandbox`. Also wiped the entire local repo once via `git clean -fdx` |
| **Gemini** (`gemini-3-pro-preview`) | Strong at bulk implementation — 466/852 CS8618 nullable warnings fixed in a single session | Probably capable, but rate limits make it unusable. Paid tier limits nearly identical to free tier. Workspace sandbox restricts file access to CWD only. `gemini-2.5-flash` was fast but superficial. `gemini-3.1-pro` returned 404 in API. Days of integration work for a model we can barely use |
| **Claude** (`claude-sonnet-4-6`) | Most reliable for implementation, no practical rate limits | Most expensive. Opus (5x cost) as fallback |
| **Claude Opus** (`claude-opus-4-6`) | Far better suited for supervision and orchestration — more prudent, efficient, clear. Conveys a confidence in problem management that Sonnet doesn't. The right model for reviewing, planning, and deciding, not just coding | Too expensive for routine implementation. Best used as the "brain" overseeing cheaper "hands" |

**The double-pay problem:** Sonnet fails → retry with Opus = paying twice for the same issue. This pattern accounted for **27% of total API spend**.

**Rate limit amnesia:** Without persistent tracking, every orchestrator restart wasted 40+ minutes trying agents that were still rate-limited.

#### Gen 3: The 31-Hour Disaster (Feb 17) — The Post-Mortem That Changed Everything

A single orchestrator run produced 247 test invocations. Only 46 actually ran tests. The other 201 completed in <1 second with 0 tests — **phantoms** that the orchestrator accepted as "passing."

**Root cause:** `mRemoteNG.sln` didn't include the test projects. An AI agent had added them locally but never committed the `.sln` change. The orchestrator ran `dotnet test` on a solution with no tests — which succeeds instantly.

**What went wrong:**
- 31 commits in the first 10 hours (productive), then nothing useful for 21 hours
- The orchestrator accepted a **353.7% pass rate** (passed > total) as valid — no sanity check
- Three concurrent orchestrator instances ran simultaneously (no single-instance lock) — garbled test output
- No circuit breaker — after 5 consecutive failures, it kept trying
- On any test failure, the orchestrator immediately reverted instead of attempting a fix — discarding potentially hours of work
- **BitDefender ATD quarantined `mRemoteNG.dll`** after 247 rapid build-delete cycles. The kernel minifilter driver blocks the exact filename even after "disabling" BitDefender. Fix required: restore from quarantine, exclude from ALL BD modules, and **reboot** (kernel driver caches the block list)

**The lesson:** An orchestrator without monitoring is more dangerous than manual work. It can destroy a night's worth of progress while you sleep.

#### Gen 4: Self-Healing Supervisor + Claude-Only (Feb 18–28) — What Worked

The architecture that actually produced results:

```
orchestrator_supervisor.py (~800 lines)
  │ monitors heartbeat (30s), manages 12 failure modes
  │
  └─► iis_orchestrator.py (~6,100 lines)
        │ sync → triage → implement → verify → commit
        │
        ├─► Claude Sonnet (primary — fast, cost-effective)
        │     └─► Claude Opus (escalation — when Sonnet fails)
        │
        └─► Independent Verification (no AI — deterministic)
              1. build.ps1 (MSBuild)
              2. run-tests-core.sh (5,967 tests, 9 groups)
              3. git commit (green) OR git restore (red)
```

**12 failure modes handled automatically (FM1–FM12):**

| FM | Problem | Detection | Recovery |
|----|---------|-----------|----------|
| FM1 | Stale lock file | PID dead or lock >N hours old | Delete lock |
| FM2 | Multiple instances | >1 orchestrator process | Kill all but oldest |
| FM3 | Phantom test processes | Lingering `testhost.exe` | `taskkill /F` |
| FM4 | Rate-limit file corruption | Expired entries or corrupt JSON | Clean/recreate |
| FM5 | Status file corruption | Invalid JSON | Backup + recreate |
| FM6 | Hung process | No status update >30 min | Kill + clean lock |
| FM7 | Crashed process | Lock PID is dead | Remove lock, kill stale |
| FM8 | Stale editor processes | Lingering `notepad.exe`, `mstsc.exe` | Kill by name |
| FM9 | Git state dirty | Merge/rebase in progress, detached HEAD | Stash, abort, checkout main |
| FM10 | All agents blocked | All rate-limited simultaneously | Dormancy until earliest reset |
| FM11 | No progress | 0 commits in 60 min or issue stuck >30 min | Progressive strikes (warn → kill → hard kill) |
| FM12 | Build infra failure | 3+ consecutive build failures (DLL locked, AV, disk) | Kill MSBuild, test build, conditional restart |

**Key design decisions:**
- **Test-fix-first:** Instead of immediately reverting on test failure, the AI gets 2 attempts to fix the failing test — recovering work that would otherwise be discarded
- **Circuit breaker:** 5 consecutive failures → verify baseline → stop if infrastructure is broken
- **Phantom detection:** 3 layers — PowerShell exit codes (97-99), Python validation, JSON sanity check
- **Persistent rate-limit tracking:** Saves 40+ min/session by instantly skipping blocked agents
- **Chain context reuse:** Each agent in the escalation chain receives previous agents' failed attempts as context

### The Economics — What It Actually Costs

Analysis from `cost_analysis.py` (12-section report against orchestrator logs):

**Cost by task type:**

| Task | Avg. cost/call | Notes |
|------|---------------|-------|
| Triage | ~$0.20 | Cheap — not worth optimizing |
| Implementation | ~$1.68 | Bulk of the spend |
| Test fix | ~$1.75 | Similar to implementation |

**Cost by model:**

| Model | % of total spend | Role |
|-------|-----------------|------|
| Claude Opus | 58% | Most reliable, most expensive |
| Gemini Pro | 24% | Bulk implementation (Gen 2) |
| Codex Spark | 18% | Fast triage |

**Where money was wasted:**
- **Double-pay (Sonnet→Opus):** 27% of total — the single biggest waste category
- **Failed issues:** 10% — issues that consumed API calls but produced no commit
- **Pre-analysis phase:** <1% (disabled after proving ineffective)

**Learning curve — cost per commit:**

| Day | $/commit | Why |
|-----|----------|-----|
| Day 1 | $4.02 | No persistent rate tracking, no circuit breaker, Opus overuse |
| Day 4 | $1.49 | Codex functional, persistent tracking, chain context reuse |

**Output tokens = 97% of cost.** Output tokens cost 5x input tokens. The output/input ratio was 4:1. Every verbose explanation an AI agent writes is burning money.

**Bottom line:** Only max-tier subscriptions with the best models produce cost-effective results. Intermediate tiers (Gemini Pro with near-free-tier limits, Codex with usage resets) generate retry overhead that erases the savings. The stabilized cost of ~$1.50/commit is comparable to a junior developer's hourly rate — but the orchestrator works 24/7.

### What Didn't Work — The Failure Catalog

**AI agent sandbox limitations:**
- Codex on Windows: Linux sandbox cannot run PowerShell, MSBuild, or COM references — the three things this project requires
- Gemini workspace sandbox: file access restricted to CWD — can't read solution-level files
- Gemini rate limits: paid tier with limits nearly identical to free tier
- GPT-4.1: `workspace-write` fails entirely on Windows

**The 31-hour disaster (detailed above):**
- 201 phantom test runs accepted as passing
- 353.7% pass rate accepted without question
- 3 concurrent orchestrator instances with garbled output
- BitDefender quarantine after 247 build cycles

**7 AI-introduced regressions that passed ALL 5,967 automated tests (beta.5):**

| Regression | What the AI did | Why tests didn't catch it |
|------------|----------------|--------------------------|
| Phantom tabs on tree click | Added preview-on-select as unsolicited "feature" | No test for "clicking tree doesn't open tabs" |
| Focus stealing on tab switch | Added `ActivateConnection` on `SelectedIndexChanged` | Focus behavior requires real window interaction |
| PuTTY root destroying confCons.xml | Added save logic for read-only PuTTY session imports | Save/load round-trip wasn't tested end-to-end |
| Tab close hang | Dispose sequence wrong for disconnected connections | Tests don't simulate disconnected COM objects |
| COM RCW crashes | Disposed ActiveX control already detached | COM lifecycle is inherently hard to unit test |
| Portable settings → %AppData% | Missing `PORTABLE` define in some configurations | Settings path depends on build configuration |
| .NET 10 SettingsProvider | Framework change broke attribute-based resolution | Requires runtime .NET 10 behavior |

**SonarCloud Quality Gate failure (beta.5 PR #3188):** Codex attempted to fix Sonar issues but introduced 2 CRITICAL bugs + 1 BLOCKER — incorrect method inlining, bypassed property flow, incomplete Dispose pattern.

**Parallelization attempts (days of work, zero success):**
- **NUnit `[assembly: Parallelizable]`**: 27 failures from race conditions on shared mutable singletons (`DefaultConnectionInheritance.Instance`, `Runtime.EncryptionKey`, `Runtime.ConnectionsService`). Every attempt to make singletons thread-safe cascaded into more failures. Abandoned after 3 days — multi-process isolation is the only viable approach.
- **MSBuild `-m` scaling**: With only 3 projects in the solution, parallelism maxes out at ~4 effective cores regardless of CPU. The 587-file main project is the bottleneck — Roslyn parallelizes file compilation internally but there's no way to split a single project across build agents.
- **Concurrent orchestrator agents**: Running 2+ AI agents in parallel on the same repo caused git conflicts, garbled test output, and file locks. Tried worktrees, separate clones, and output directory isolation — all failed on Windows due to MSBuild file locking and shared COM registration. Serial execution remains the only reliable approach.

**Codex deleted the entire local repository (Feb 27):**
- Codex agent ran `git clean -fdx` followed by operations that wiped all untracked and ignored files — including build outputs, local configs, and uncommitted work
- Everything since the last `git push` was lost permanently. Hours of local-only changes, test configurations, and debugging notes — gone
- **Lesson learned the hard way:** Push early, push often. Local repo is NOT a backup. The orchestrator now pushes after every successful commit, not in batches. And we keep a second clone as cold backup.

**Infrastructure pitfalls:**
- `subprocess.run(timeout=T)` on Windows: hangs indefinitely when child processes inherit pipe handles
- PowerShell 5.1: Unicode em-dash corrupts the parser at a completely unrelated `}`
- `dotnet build` fails with COM references (`MSB4803`) — must use full MSBuild

### What Worked — The Success Patterns

- **585 issues addressed** out of 838 tracked (70%), 1,365 commits in February 2026
- **5,967 tests** (up from 2,179 at v1.79.0), 0 failures
- **Self-healing supervisor:** 12 failure modes handled automatically — zero human babysitting
- **Test-fix-first:** 2 fix attempts before revert — recovers work that would otherwise be lost
- **Circuit breaker:** 5 consecutive failures → baseline check → stop if infrastructure is broken
- **Phantom detection:** 3-layer validation eliminated false-positive test runs entirely
- **Persistent rate tracking:** 40+ min/session saved by instant skip of blocked agents
- **Chain context reuse:** each escalation carries previous attempts → fewer repeated mistakes
- **Cost stabilization:** $4.02/commit (day 1) → $1.49/commit (day 4)

### Key Insights

1. **Automated tests are necessary but NOT sufficient.** Focus handling, save/load round-trips, COM lifecycle, and settings persistence cannot be fully covered by unit tests. Manual testing remains irreplaceable for UX validation.

2. **AI agents add unsolicited "features."** Event handlers, `Focus()` calls, save logic that didn't exist — AI models optimize for "completeness" and will add code that wasn't requested. This is their most dangerous behavior.

3. **Only max-tier subscriptions are cost-effective.** Intermediate tiers generate retry overhead (rate limits, sandbox failures) that erases the savings. The cheapest path is the most capable model with the fewest retries.

4. **Simplicity beats complexity.** 3-agent orchestra (Gen 2) → 1 primary agent with fallback (Gen 4). Fewer moving parts, fewer failure modes, more reliable.

5. **Different models for different roles.** Codex Spark is unmatched for fast code interpretation and implementation — reliable, cheap, instant. Opus is the right choice for supervision, planning, and decision-making — prudent, efficient, and clear in a way that inspires confidence. Sonnet is the workhorse in between. Gemini is probably capable but rate limits make it practically unusable. The optimal architecture is Opus as the "brain" orchestrating Spark/Sonnet as the "hands."

6. **Human oversight remains essential.** 7 regressions out of 585 issues is ~1.2% — but one of them (PuTTY root save) would silently destroy all user connections. Percentages don't capture severity.

7. **Self-healing beats manual monitoring.** The supervisor eliminated 24/7 babysitting. 12 failure modes × multiple occurrences each = hundreds of manual interventions avoided.

8. **AI agents will destroy your local repo.** Codex wiped the entire local clone with `git clean -fdx`. Push after every commit. Keep a cold backup clone. Treat local state as ephemeral — if it's not pushed, it doesn't exist.

### Rules for AI Agent Development (Added After Failures)

These rules were added to the orchestrator's agent prompts after each failure. They represent hard-won knowledge:

- No event handlers on `SelectionChanged` without human approval
- No `Protocol.Focus()` outside explicit user action
- Validate save/load round-trip (`confCons.xml` must survive save → load → save)
- No modifications to `WndProc`, `Dispose`, or COM interop without human review
- Protected files (orchestrator, supervisor, configs) excluded from `git restore`
- Max 2 retries per issue before `needs_human` flag
- Phantom test detection mandatory at every test run
- Never run `git commit/add/push` — the orchestrator handles all commits
- Never create interactive tests (no MessageBox, no dialogs, no user input prompts)
- `--verbosity normal` only (minimal/quiet crashes testhost on .NET 10)

---

## Release History

| Version | Date | Highlights |
|---------|------|------------|
| **v1.81.0-beta.5** | 2026-02-27 | 7 manual-testing regressions fixed, AV false positive hardening (`SendInput`, `DefaultDllImportSearchPaths`, VirusTotal in CI), `PortableSettingsInitializer` for .NET 10, 5,967 tests |
| **v1.81.0-beta.4** | 2026-02-25 | AV hardening, test suite expansion 2,916 → 5,967 via `TestCaseSource` parametrization |
| **v1.81.0-beta.3** | 2026-02-24 | 585 issues addressed (70% of 838), 744 commits, 7 new protocols, 81s→ms deserialization fix, orchestrator v2 (Claude-only, self-healing supervisor) |
| **v1.81.0-beta.2** | 2026-02-15 | 2,554 nullable warnings fixed (100% clean, 242 files), testable architecture via DI |
| **v1.80.2** | 2026-02-14 | AlwaysShowPanelTabs initialization fix |
| **v1.80.1** | 2026-02-13 | Security patch — AnyDesk command injection, Process.Start hardening, .NET 10.0.3 |
| **v1.80.0** | 2026-02-10 | Self-contained builds, 6 security hardening items, external tool tokens, JSON export, live theme switching, 830-issue triage complete |
| **v1.79.0** | 2026-02-08 | 26 bug fixes, 81 pre-existing test failures fixed, LDAP sanitizer, .NET 10 with x64/x86/ARM64 |

Full details: [CHANGELOG.md](CHANGELOG.md) | [All releases](https://github.com/robertpopa22/mRemoteNG/releases)

---

## Build from Source

```powershell
# Requires Visual Studio BuildTools (VS2026 or VS2022) with .NET SDK
# Full build (~15s on 48-thread Threadripper):
pwsh -NoProfile -ExecutionPolicy Bypass -File build.ps1

# Fast incremental (~9s, skips restore):
pwsh -NoProfile -ExecutionPolicy Bypass -File build.ps1 -NoRestore

# Self-contained (embeds .NET runtime, ~108-116MB output):
pwsh -NoProfile -ExecutionPolicy Bypass -File build.ps1 -SelfContained
```

> **Note:** `dotnet build` does **not** work — the project has COM references (MSTSCLib for RDP). `build.ps1` uses full MSBuild via VS BuildTools and auto-detects the newest VS installation.

### Code Quality

| Level | Tool | Scope | Status |
|-------|------|-------|--------|
| 1 | **Roslynator + Meziantou Analyzers** | Every local build | Active |
| 2 | **SonarCloud** | Push to `main` — quality gate | [![SonarCloud](https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/sonarcloud.yml?label=SonarCloud&style=flat-square)](https://sonarcloud.io/project/overview?id=robertpopa22_mRemoteNG) |
| 3 | **CodeQL** | Push to `main` + weekly — security scanning | [![CodeQL](https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/codeql.yml?label=CodeQL&style=flat-square)](https://github.com/robertpopa22/mRemoteNG/security/code-scanning) |
| 4 | **.NET Analyzers** | `AnalysisLevel=latest-recommended` | Active |

Gradual adoption — all rules are warnings (not errors). Noisy rules for legacy WinForms code are suppressed. Rules tighten as the codebase improves.

---

## Testing

```powershell
# Recommended (bash runner, 9 groups, max 2 concurrent, ~80s):
bash run-tests-core.sh

# PowerShell wrapper (builds first):
pwsh -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1 -Headless

# Skip build (use existing binaries):
pwsh -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1 -Headless -NoBuild
```

**5,967 tests**, 9 groups with sliding-window concurrency (max 2), 0 failures.

Multi-process parallelism is required because the production code uses shared mutable singletons — NUnit fixture-level parallelism causes race conditions. Each `dotnet test` process gets isolated static state.

| Group | Namespace | Tests |
|-------|-----------|-------|
| 1 | Connection | 1,066 |
| 2 | Config.Xml | 124 |
| 3 | Config.Other | 706 |
| 4 | UI | 375 |
| 5 | Tools | 366 |
| 6 | Security | 166 |
| 7 | Tree + Container + Credential | 178 |
| 8 | Remaining | 2,961 |
| 9 | Integration | 21 |
| Isolated | FrmOptions (GDI handle leak) | 2 |

---

## Upstream Relationship

This fork is based on [mRemoteNG/mRemoteNG](https://github.com/mRemoteNG/mRemoteNG) `v1.78.2-dev`. We submit fixes back upstream:

- v1.79.0: PRs [#3105](https://github.com/mRemoteNG/mRemoteNG/pull/3105)–[#3130](https://github.com/mRemoteNG/mRemoteNG/pull/3130) (26 individual PRs)
- v1.80.0: [#3133](https://github.com/mRemoteNG/mRemoteNG/issues/3133) (consolidated status)
- v1.81.0-beta.5: [#3188](https://github.com/mRemoteNG/mRemoteNG/pull/3188)

---

## License

[GPL-2.0](COPYING.TXT)

## Support the Project

If you find this fork useful, please consider giving it a star — it helps others discover the project and motivates continued development.

<p align="center">
  <a href="https://github.com/robertpopa22/mRemoteNG/stargazers">
    <img alt="Star this repo" src="https://img.shields.io/github/stars/robertpopa22/mRemoteNG?style=for-the-badge&label=Star%20on%20GitHub&color=yellow">
  </a>
</p>

## Contributing

Submit code via pull request. See the [Wiki](https://github.com/mRemoteNG/mRemoteNG/wiki) for development environment setup.
