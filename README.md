<p align="center">
  <img width="450" src="https://github.com/mRemoteNG/mRemoteNG/blob/mRemoteNGProjectFiles/Header_dark.png">
</p>

# mRemoteNG — Community Edition

<blockquote>

<strong>This fork is alive.</strong>

We love mRemoteNG and we're committed to keeping it moving forward. This Community Edition ships regular releases with security patches, bug fixes, and long-requested features — backed by proper CI, <strong>2,817 automated tests</strong>, and builds for x64, x86, and ARM64.

<strong>Marching to Zero Backlog:</strong> 838 issues tracked, <strong>585 addressed in code (70%)</strong>, 25 released and confirmed. We're tackling the entire backlog in one push — organize, automate, attend to every detail. Nothing gets left behind. Every issue gets triaged, every fix gets tested, every reporter gets a response. Security first, then stability, then features.

<strong>How we work:</strong> A Python <strong>orchestrator</strong> coordinates three AI agents — <strong>Codex</strong> (OpenAI) for fast triage, <strong>Gemini CLI</strong> (Google) for bulk code transformations, and <strong>Claude Code</strong> (Anthropic) for complex multi-file fixes and final review. Per issue, agents run as a fallback chain (Codex first, then Gemini, then Claude) with Sonnet-to-Opus escalation for the hardest problems. Every change is independently verified (build + 2,817 tests) before commit. A <strong>self-healing supervisor</strong> handles 8 failure modes automatically. A custom <strong>Issue Intelligence System</strong> — a git-tracked JSON database — follows every issue through its full lifecycle: triage → fix → test → release. Automated priority classification and templated GitHub comments ensure nothing falls through the cracks.

<strong>What's next:</strong> Once the backlog is current, ongoing maintenance — bug fixes, dependency updates, security patches — will run autonomously via <a href="https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview">Claude Code</a>, continuously monitoring new issues and shipping fixes with minimal human intervention.

Full transparency: this project is built by humans and AI working together. We believe that's the future of open source.

<em>— Robert & contributors (human + AI)</em>

</blockquote>

<p align="center">
  <a href="https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.81.0-beta.3">
    <img alt="Beta" src="https://img.shields.io/badge/beta-v1.81.0--beta.3-orange?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/tree/main">
    <img alt="Next" src="https://img.shields.io/badge/next-v1.81.0--beta.4-blue?style=for-the-badge">
  </a>
  <a href="https://github.com/robertpopa22/mRemoteNG/actions">
    <img alt="CI" src="https://img.shields.io/github/actions/workflow/status/robertpopa22/mRemoteNG/pr_validation.yml?style=for-the-badge&label=CI">
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

## Latest Stable Release

<a href="https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.76.20">
  <img alt="Stable v1.76.20" src="https://img.shields.io/badge/stable-v1.76.20-blue?style=for-the-badge">
</a>

The latest production-ready version of mRemoteNG. For most users, this is the recommended version.

---

## Beta Builds (Main Branch)

<a href="https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.81.0-beta.3">
  <img alt="Beta v1.81.0-beta.3" src="https://img.shields.io/badge/beta-v1.81.0--beta.3-orange?style=for-the-badge">
</a>

> [!IMPORTANT]
> These are high-velocity builds from the `main` branch. They include the latest .NET 10 updates, security hardening, and experimental features. Use these if you want to help test new functionality. A version is promoted to **Stable** only after at least 5 beta iterations.

| Variant | x64 | x86 | ARM64 |
|---------|-----|-----|-------|
| Framework-dependent (~21MB) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-x64.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-x86.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-arm64.zip) |
| Self-contained (~108-116MB) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-win-x64-SelfContained.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-win-x86-SelfContained.zip) | [Download](https://github.com/robertpopa22/mRemoteNG/releases/download/v1.81.0-beta.3/mRemoteNG-v1.81.0-beta.3-win-arm64-SelfContained.zip) |

**Framework-dependent** requires [.NET Desktop Runtime 10.0](https://dotnet.microsoft.com/download/dotnet/10.0).
**Self-contained** includes the .NET runtime — no prerequisites needed.

---

<details open>
<summary><strong>What's in v1.81.0-beta.3?</strong> (585 issues addressed — largest release ever)</summary>

### Highlight: Marching to Zero Backlog
**744 commits**, **585 issues addressed** (70% of 838 tracked), **2,817 tests** passing with 0 failures. The multi-agent orchestrator was rearchitectured with a self-healing supervisor, chain context reuse, and Sonnet-to-Opus escalation.

### New Features
- **Reconnect** in context menu (#1233), **folder path on tab names** (#3083), **ADMX/ADML Group Policy templates** (#738)
- **7 new protocols**: VMRC, MSRA, OpenSSH, Winbox, WSL, Terminal, Serial

### Security
- 4 GitHub code scanning alerts fixed (SOCKS5, ReDoS, workflow permissions, insecure deserialization)
- CVE-2020-0765 mitigation, PBKDF2 improvements, thread-safe BouncyCastle GCM

### Performance
- **81s → ms** deserialization fix for 570+ connections (#12)
- Thread-safe parallel decryption, build time 24s → 9s

### Bug Fixes (585 issues across all categories)
- **RDP** (~80): SmartSize, fullscreen, gateway, monitor hot-plug, NLA, reconnection
- **VNC** (~40): crash fixes, color depth, clipboard sync, authentication fallback
- **SSH/PuTTY** (~30): CJK names, tunnel TOCTOU, key exchange, SFTP
- **UI/UX** (~60): panel races, tab drag, theme consistency, Options panel fixes
- **Credentials** (~40): 1Password, master password autolock, vault HTTPS enforcement
- **Database** (~50): SQL schema compat, transaction safety, XML recovery
- **Connections** (~80): external tool tokens, audit logging, quick connect history
- **Themes** (~20): live switching, dark mode colors, DockPanel integration
- **Windows** (~30): DPI PerMonitorV2, splash screen, tab overflow

### Architecture
- Multi-agent orchestrator v2 with self-healing supervisor (8 failure modes)
- Chain context reuse, token tracking, duplicate commit prevention
- Decoupled connection loaders via DI, new SQL abstractions

### Dependencies
- Microsoft.NET.Test.Sdk 18.3.0, actions/checkout v6, signpath v2
- 67 upstream commits merged from v1.78.2-dev

See [CHANGELOG.md](CHANGELOG.md) for the full list.

</details>

<details>
<summary><strong>Previous release: v1.81.0-beta.2</strong> (2026-02-15, zero nullable warnings)</summary>

- **Zero Nullable Warnings** — 2,554 CS8xxx warnings fixed across 242 files (100% clean)
- **Testable Connection Loaders** — SqlConnectionsLoader & XmlConnectionsLoader via DI
- **AnyDesk command injection prevention** — IsValidAnydeskId() validation
- **2,349 tests**, 0 failures, 5 parallel processes

</details>

<details>
<summary><strong>Previous release: v1.80.2</strong> (2026-02-14, maintenance)</summary>

- **AlwaysShowPanelTabs initialization fix** ([#3142](https://github.com/mRemoteNG/mRemoteNG/issues/3142)) — panel tabs setting no longer corrupts Options on startup

</details>

<details>
<summary><strong>Previous release: v1.80.1</strong> (2026-02-13, security patch)</summary>

### Security Fixes (upstream merge)
- **AnyDesk command injection prevention** — `IsValidAnydeskId()` validates IDs before passing to process
- **Process.Start hardening** — `ProcessStartInfo` with `UseShellExecute` across all UI forms
- **URL format validation** in FrmAbout — rejects non-HTTP(S) URLs
- **Path validation** in NotificationsPage — prevents command injection via log file paths

### Dependency Updates
- .NET SDK 10.0.2 → 10.0.3 (runtime security patch)
- Removed 27 redundant System.* NuGet packages (now built-in to .NET 10)
- Updated AWS SDK packages

</details>

<details>
<summary><strong>Previous release: v1.80.0</strong> (self-contained builds, security hardening, new features)</summary>

### Highlights
- **Self-contained build variant** — includes .NET runtime, no install needed
- **6 security hardening items** — encryption keys, auth levels, PBKDF2 600K, SSH wipe, HTTPS vaults
- **External tool tokens** — `%PUTTYSESSION%`, `%ENVIRONMENTTAGS%`, `%SSHOPTIONS%`
- **Options panel stability** — Cancel properly reverts, SQL fields work
- **Batch file password fix** — comma in passwords no longer splits args

### New Features
- Self-contained (.NET embedded) build — no .NET runtime installation required
- JSON export, protocol/tag filtering, quick connect history
- Connection audit log, keyboard shortcuts panel
- Middle-click: open connection from tree, close tab
- Live theme switching (no restart), crash dialog auto-submit

[v1.80.0 release page](https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.80.0)

</details>

<details>
<summary><strong>Previous release: v1.79.0</strong> (26 bug fixes, security hardening, test suite)</summary>

### Bug Fixes (26 total)
- **RDP:** SmartSize focus loss, fullscreen toggle guard, refocus after exit, RCW disconnect safety
- **PuTTY:** Provider failure handling, CJK session name decoding
- **UI:** Close panel race, tab drag autoscroll, tab close race under resize, empty panel close, config panel splitter, inheritance label width, connections panel focus
- **Data:** 1Password parser fix, SQL schema compatibility, SqlClient SNI runtime, default credential provider
- **Core:** Startup path fallback, XML recovery for corrupt configs, main form close cancel, master password autolock, PROTOCOL external tool token, settings path logging, password protection verification

### Quality
- 2179 tests passing (81 pre-existing failures fixed, 31 new tests added)
- .NET 10, 3-architecture support (x64, x86, ARM64)

[v1.79.0 release page](https://github.com/robertpopa22/mRemoteNG/releases/tag/v1.79.0)

</details>

[View all releases](https://github.com/robertpopa22/mRemoteNG/releases)

---

## Features

The following protocols are supported:

* RDP (Remote Desktop Protocol)
* VNC (Virtual Network Computing)
* SSH (Secure Shell)
* Telnet (TELecommunication NETwork)
* HTTP/HTTPS (Hypertext Transfer Protocol)
* rlogin (Remote Login)
* Raw Socket Connections
* Powershell remoting
* AnyDesk
* VMRC (VMware Remote Console)
* MSRA (Microsoft Remote Assistance)
* OpenSSH (Native Windows OpenSSH client)
* Winbox (MikroTik router management)
* WSL (Windows Subsystem for Linux)
* Terminal (Generic terminal emulator)
* Serial (COM port connections)

For a detailed feature list and general usage support, refer to the [Documentation](https://mremoteng.readthedocs.io/en/latest/).

---

## Installation

### Supported Operating Systems

- Windows 11
- Windows 10
- Windows Server 2022
- Windows Server 2019
- Windows Server 2016

### How to Update (Portable ZIP)

1. Download the ZIP for your architecture
2. Extract over your existing mRemoteNG installation
3. Your `confCons.xml` and settings are preserved

---

## Build from Source

```powershell
# Requires Visual Studio BuildTools (VS2026 or VS2022) with .NET SDK
# Full build (~15s on 48-thread Threadripper):
powershell.exe -NoProfile -ExecutionPolicy Bypass -File build.ps1

# Fast incremental (~9s, skips restore):
powershell.exe -NoProfile -ExecutionPolicy Bypass -File build.ps1 -NoRestore

# Self-contained (embeds .NET runtime, ~108-116MB output):
powershell.exe -NoProfile -ExecutionPolicy Bypass -File build.ps1 -SelfContained
```

> **Note:** `dotnet build` does **not** work — the project has COM references (MSTSCLib for RDP). `build.ps1` uses full MSBuild via VS BuildTools and auto-detects the newest VS installation.

### Build optimization

A `Directory.Build.props` at the solution root configures:
- **`UseSharedCompilation=true`** — keeps the Roslyn compiler server warm between builds
- **`NoWarn=CA1416`** — suppresses 1,795 platform compatibility warnings (app is 100% Windows-only)

MSBuild `-m` parallelizes at project level (3 projects), while Roslyn parallelizes file compilation internally. On a 48-thread CPU, the bottleneck is the single 587-file main project — adding more cores beyond ~4 has no effect.

---

## Testing

```powershell
# Parallel (5 processes, ~2 min) — recommended:
powershell.exe -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1

# Skip build (use existing binaries):
powershell.exe -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1 -NoBuild

# Sequential (single process):
powershell.exe -NoProfile -ExecutionPolicy Bypass -File run-tests.ps1 -Sequential
```

**Current status:** 2,817 tests across 5 parallel processes, 0 failures, 0 skipped.

Multi-process parallelism is required because the production code uses shared mutable singletons (`DefaultConnectionInheritance.Instance`, `Runtime.ConnectionsService`, `Runtime.EncryptionKey`) — NUnit fixture-level parallelism causes race conditions. Each `dotnet test` process gets isolated static state.

| Process | Namespace | Tests |
|---------|-----------|-------|
| 1 | Security | 198 |
| 2 | Tools + Messages + App + misc | 421 |
| 3 | Config | 697 |
| 4 | Connection + Credential + Tree + misc | 1,143 |
| 5 | UI (RunWithMessagePump pattern) | 358 |

---

## Upstream Relationship

This fork is based on [mRemoteNG/mRemoteNG](https://github.com/mRemoteNG/mRemoteNG) `v1.78.2-dev`.
v1.79.0 fixes have individual PRs on upstream ([#3105](https://github.com/mRemoteNG/mRemoteNG/pull/3105)–[#3130](https://github.com/mRemoteNG/mRemoteNG/pull/3130)).
v1.80.0 consolidated status: [#3133](https://github.com/mRemoteNG/mRemoteNG/issues/3133).

---

## What's New

### v1.81.0-beta.3 (2026-02-24) — 585 Issues Addressed
- **Marching to Zero Backlog** — 838 issues tracked, 585 addressed (70%), 25 released
- **744 commits**, 67 upstream commits merged, 2,817 tests (0 failures)
- **7 new protocols** — VMRC, MSRA, OpenSSH, Winbox, WSL, Terminal, Serial
- **Security** — 4 code scanning alerts fixed, CVE-2020-0765, thread-safe encryption
- **Performance** — 81s → ms deserialization, parallel decryption, 9s builds
- **Orchestrator v2** — self-healing supervisor, chain context reuse, Sonnet→Opus escalation
- **Features** — Reconnect menu (#1233), folder path tabs (#3083), ADMX templates (#738)

### v1.81.0-beta.2 (2026-02-15)
- **Zero Nullable Warnings** — 2,554 fixed across 242 files via multi-agent orchestrator
- **2,349 tests**, testable architecture (DI), AnyDesk security fix

### v1.80.2 (2026-02-14)
- **AlwaysShowPanelTabs initialization fix** ([#3142](https://github.com/mRemoteNG/mRemoteNG/issues/3142))

### v1.80.1 (2026-02-13)
- **Security patch** — AnyDesk command injection fix, Process.Start hardening, URL/path validation (upstream merge)
- **.NET 10.0.3** runtime patch + removed 27 redundant packages
- **CI improvements** — self-contained build matrix, actions/setup-dotnet v5

### v1.80.0 (2026-02-10)
- **Self-contained builds** — .NET runtime included, zero prerequisites
- **Security hardening** — PBKDF2 600K iterations, HTTPS-only vaults, SSH key wipe, stronger master passwords
- **New tokens** — `%PUTTYSESSION%`, `%ENVIRONMENTTAGS%`, `%SSHOPTIONS%` for external tools
- **Options panel fixes** — Cancel reverts properly, SQL fields work, panel tabs no longer corrupt layout
- **RDP improvements** — auto-resize on monitor hot-plug, async initialization
- **New features** — JSON export, protocol/tag filtering, connection audit log, live theme switching

### v1.79.0 (2026-02-09)
- **26 bug fixes** — RDP, PuTTY, UI, SQL, credential providers
- **81 pre-existing test failures fixed** — 2179 tests, zero failures
- **LDAP sanitizer** and process-start hardening
- **.NET 10** with x64, x86, ARM64 support

Full details: [CHANGELOG.md](CHANGELOG.md) | [All releases](https://github.com/robertpopa22/mRemoteNG/releases)

---

## Multi-Agent Orchestrator

Development is driven by a Python orchestrator (`iis_orchestrator.py`) that coordinates three AI agents, with independent verification at every step.

### Architecture

```
                           ┌─────────────────────────────┐
                           │   iis_orchestrator.py        │
                           │   (Python — control loop)    │
                           │   + self-healing supervisor   │
                           └──────────┬──────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
   ┌──────────▼──────────┐ ┌─────────▼──────────┐ ┌─────────▼──────────┐
   │  Codex (OpenAI)     │ │ Gemini CLI (Google) │ │ Claude Code        │
   │                     │ │                     │ │ (Anthropic)        │
   │  • Fast triage      │ │ • Bulk transforms   │ │ • Complex fixes    │
   │  • Simple fixes     │ │ • Nullable cleanup  │ │ • Multi-file edits │
   │  • ~15-30s/issue    │ │ • 466 warnings/run  │ │ • Sonnet → Opus    │
   │  • Priority P0-P4   │ │ • Cascading types   │ │ • Corrects others  │
   └──────────┬──────────┘ └─────────┬──────────┘ └─────────┬──────────┘
              │                       │                       │
              └───────────────────────┼───────────────────────┘
                                      │ code changes
                           ┌──────────▼──────────────────┐
                           │  Independent Verification    │
                           │  (no AI — deterministic)     │
                           │                              │
                           │  1. build.ps1 (MSBuild)      │
                           │  2. run-tests.ps1 (2,817)    │
                           │  3. git commit OR git restore │
                           │  4. gh issue comment          │
                           └──────────────────────────────┘
```

### Agent selection (fallback chain)

Each issue flows through agents as a fallback chain — if the first agent fails to produce a passing build+test, the next one takes over:

1. **Codex** attempts first (fastest, cheapest)
2. If Codex fails → **Gemini CLI** retries (better at bulk/pattern changes)
3. If Gemini fails → **Claude Code** takes over (best at complex reasoning)
4. If all fail → issue is logged, skipped, and flagged for human review

### Verification layer

The orchestrator **never trusts agent output**. After every code change:
- `build.ps1` must compile cleanly (MSBuild, all 3 projects)
- `run-tests.ps1` must pass all 2,817 tests (5 parallel processes)
- On success: atomic commit (`fix(#NNNN): description`) + push
- On failure: `git restore` immediately, log error, move to next issue
- On release: templated comment posted to upstream issue via `gh`

### Results (v1.81.0-beta.3)

| Metric | Value |
|--------|-------|
| Total commits since beta.2 | 744 |
| Issues tracked | 838 |
| Issues addressed in code | 585 (70%) |
| Issues released + confirmed | 25 |
| Nullable warnings fixed | 2,554 (100% clean) |
| Tests passing | 2,817 (0 failures) |
| Upstream commits merged | 67 |
| Orchestrator failure modes handled | 8 (self-healing) |
| Test regressions introduced | 0 |

## Issue Intelligence System

The orchestrator includes a git-tracked JSON database that monitors the full upstream issue backlog and automates triage, lifecycle tracking, and release communication.

**What it does:**
- Syncs issues and comments from both upstream and fork repositories via `gh` CLI
- Tracks each issue through a full lifecycle: `new` → `triaged` → `roadmap` → `in-progress` → `testing` → `released`
- Detects **iteration loops** — when a user reports a fix didn't fully resolve their issue, the system tracks re-fix cycles
- Posts templated comments to GitHub on status transitions (release notifications, acknowledgements)
- Generates markdown reports for triage sessions and releases
- Auto-classifies issues by priority based on labels and comment activity

**Commands:**

```bash
# Sync issues from GitHub (always run first)
python .project-roadmap/scripts/iis_orchestrator.py sync

# Analyze what needs attention
python .project-roadmap/scripts/iis_orchestrator.py analyze

# Transition issue status + post GitHub comment
python .project-roadmap/scripts/iis_orchestrator.py update --issue <N> --status released --post-comment

# Generate markdown report
python .project-roadmap/scripts/iis_orchestrator.py report --include-all
```

**Current stats** (as of 2026-02-24): 838 issues tracked, 585 addressed in code (70%), 25 released, 8 duplicate, 9 wontfix.

### Marching to Zero Backlog

| Metric | Count |
|--------|-------|
| Total issues tracked | 838 |
| Addressed in code | 585 (70%) |
| Released + confirmed | 25 |
| Remaining (new/untriaged) | 253 |
| **Goal** | **0 untriaged issues** |

See [.project-roadmap/issues-db/README.md](.project-roadmap/issues-db/README.md) for full documentation.

---

## Continuous Improvement

Every success and failure is captured in a structured lessons system that feeds back into the next session. Nothing is repeated twice.

### How it works

```
  Agent runs command ──► Success? ──► Lessons updated with proven pattern
         │                               (fast fix map, timing, evidence)
         │
         └──────────► Failure? ──► Root cause analyzed immediately
                                    │
                                    ├── Exact error pattern logged
                                    ├── What was attempted (don't retry)
                                    ├── Proven fix documented
                                    └── Added to LESSONS.md
```

### What gets tracked

- **Fast Fix Map** — symptom → root cause → immediate fix (table format, searchable)
- **Build pitfalls** — MSBuild quirks, COM references, CI runner differences
- **Test flakiness** — WinForms P/Invoke tests, CueBanner race conditions, message pump deadlocks
- **Release workflow** — version bumping, CI triggers, GitHub release creation
- **Time wasters** — ranked by frequency and lost time, fixed in priority order

### Key files

| File | Purpose |
|------|---------|
| `.project-roadmap/LESSONS.md` | Master lessons — every known pitfall and proven fix |
| `.project-roadmap/CURRENT_PLAN.md` | Active plan with rules, priorities, and metrics |
| `.project-roadmap/scripts/find-lesson.ps1` | Search lessons by keyword before attempting a fix |

### Examples of lessons that saved hours

- **31-hour post-mortem** — phantom test failures caused by stale DLLs in wrong output paths; circuit breakers added to prevent cascading retries
- **Windows subprocess timeout deadlock** — `process.communicate()` with timeout prevents orphan processes in orchestrator
- **CueBanner test flakiness** (30+ min lost once, never again) — `Assume.That` on Win32 operation result, not preconditions
- **PowerShell 5.1 Unicode corruption** — em-dashes in .ps1 files break parser at random `}` far from actual issue
- **NUnit fixture parallelism** — shared mutable singletons cause 27 failures; multi-process is the only safe approach
- **Self-contained build** — `msbuild -p:SelfContained` does NOT embed runtime; must use `-t:Publish`
- **CI workflow triggers** — changes in the same commit don't take effect for that push
- **BouncyCastle GCM not thread-safe** — parallel decryption requires per-thread cipher instances

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
