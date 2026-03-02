# Hybrid AI+Human Software Maintenance: A Case Study on mRemoteNG

## Abstract

Legacy open-source projects accumulate hundreds of unresolved issues that exceed volunteer maintainer capacity. This paper presents a case study of applying a supervised AI orchestrator to mRemoteNG, a Windows remote-connections manager with 843 open GitHub issues and a legacy WinForms/.NET codebase. Over four architectural generations and approximately $320 in API costs, we developed a self-healing supervisor system coordinating multiple AI models (Codex Spark, Claude Sonnet/Opus, Gemini Pro) to autonomously triage, implement fixes, verify builds, run tests, and commit changes. The system resolved 697 of 843 issues (83%) with a 1.2% regression rate (7/585 implementations) and stabilized at $1.49 per commit by day 4 — confirming the hypothesis that a supervised AI orchestrator can resolve >50% of open issues with <2% regression and <$5/commit. The test suite grew from 2,179 to 5,963 tests with 0 failures, and SonarCloud Quality Gate passed with A ratings across all dimensions. The approach is reproducible: any project with open issues, a test suite, and a build system could apply the same model.

## 1. Introduction

### 1.1 Context

mRemoteNG is an open-source, multi-protocol remote connections manager for Windows, supporting 16 protocols (RDP, VNC, SSH, Telnet, and others). Originally built on .NET Framework with WinForms, the project had accumulated 843 open issues on GitHub with limited maintainer bandwidth to address them. The codebase contains COM interop references (MSTSCLib for RDP ActiveX), shared mutable singletons, and legacy architectural patterns that make automated modification non-trivial.

This project modernized the codebase to .NET 10, established a CI/CD pipeline with four levels of code quality analysis, and systematically addressed the issue backlog using AI-assisted development — evolving through four architectural generations of human-AI collaboration.

### 1.2 Hypothesis

**H1:** A supervised AI orchestrator can resolve **>50% of a legacy codebase's open issues** with a **regression rate <2%** and a **cost per commit under $5**, outperforming manual-only development (baseline: Gen 1, which resolved 26 issues/sprint at full human effort).

This hypothesis is falsifiable on three independent dimensions:
- Resolution rate: measurable against the 843-issue population
- Regression rate: measurable via automated tests plus manual testing protocols
- Cost per commit: measurable via API billing logs and orchestrator telemetry

### 1.3 Result Summary

697/843 issues addressed (83%), 7 regressions in 585 implementations (1.2%), cost stabilized at $1.49/commit by day 4. The hypothesis holds — but the path from "let AI fix everything" to "a self-healing supervisor coordinating AI agents with human oversight" took four architectural generations, a 31-hour disaster, and approximately $320 in API costs.

### 1.4 Paper Organization

This document presents the complete case study. Supporting documents in this folder provide detailed breakdowns:

- **[METHODOLOGY.md](METHODOLOGY.md)** — Full methodology: subject description, population, classification scheme, resolution pipeline, instruments, baseline metrics
- **[COST_ANALYSIS.md](COST_ANALYSIS.md)** — Detailed cost analysis: per-model breakdown, waste categories, learning curve, output token economics
- **[data/model_performance.md](data/model_performance.md)** — Raw performance data: timing distributions, per-model statistics, production observations
- **[EVIDENCE.md](EVIDENCE.md)** — Evidence trail: SonarCloud iterations, CI troubleshooting logs, configuration decisions
- **[RELATED_WORK.md](RELATED_WORK.md)** — Related work and references

---

## 2. Methodology

*Brief summary. Full details: [METHODOLOGY.md](METHODOLOGY.md)*

### 2.1 Subject

mRemoteNG — a legacy WinForms/.NET application (originally .NET Framework, modernized to .NET 10) with COM interop dependencies, 16 protocol implementations, and 843 open GitHub issues at project start.

### 2.2 Population

843 GitHub issues from the upstream repository (mRemoteNG/mRemoteNG), representing the complete open issue backlog as of February 2026.

### 2.3 Classification Scheme

All 843 issues were triaged and classified into four categories:

| Status | Count | % | Definition |
|--------|-------|---|------------|
| released | 502 | 59.5% | Fix committed, build/test verified, included in a release |
| testing | 195 | 23.1% | Fix committed and build-verified, awaiting manual protocol testing (RDP/SSH/VNC) |
| wontfix | 121 | 14.4% | Out-of-scope (upstream limitation, requires hardware, or not reproducible) |
| duplicate | 25 | 3.0% | Merged with another issue tracking the same root cause |

**needs_human: 0** — all 74 previously stuck issues were manually classified into testing (fixable) or wontfix (upstream limitation / requires manual RDP/SSH testing).

### 2.4 Resolution Pipeline

Issues flow through: Sync (from GitHub) → Triage (classification + approach) → Implement (code change) → Verify (build + test, deterministic, no AI) → Commit (atomic, green only) or Restore (red).

### 2.5 Instruments

- Build system: MSBuild via `build.ps1` (COM references prevent `dotnet build`)
- Test runner: `run-tests-core.sh` — 9 groups with sliding-window concurrency, multi-process isolation
- Code quality: Roslynator + Meziantou (local), SonarCloud (CI), CodeQL (CI), .NET Analyzers
- Orchestrator: `iis_orchestrator.py` (~6,100 lines Python)
- Supervisor: `orchestrator_supervisor.py` (~800 lines Python)
- Cost tracking: `cost_analysis.py` (12-section report against orchestrator logs)
- Timing data: `_timeout_history.json` (220 agent invocations)

### 2.6 Baseline

Gen 1 (manual AI-assisted development): ~26 issues resolved per sprint (~1 week), ~8 hours/day of developer attention.

### 2.7 Key Metrics

- Issues resolved (count and % of 843)
- Regression rate (regressions / implementations)
- Cost per commit (API spend / commits)
- Test count and pass rate
- Analyzer warning count
- SonarCloud Quality Gate status

---

## 3. Architecture Evolution — Four Generations of Failure and Learning

### 3.1 Gen 1: Brute Force (Early February)

Claude Sonnet on everything. Manual triage, manual implementation, manual commit.

**Result:** 26 bug fixes (v1.79.0), 2,179 tests passing, but slow — days of human work per release. Each fix required a human to read the issue, decide what to do, prompt the AI, review the code, run the build, run the tests, commit, and post a comment. The AI was a code-writing accelerator, not an autonomous agent.

**This serves as the baseline:** ~26 issues resolved per human-assisted sprint (~1 week), ~8 hours/day of developer attention. Gen 4 comparison: 89 issues in a single automated session (Feb 27), ~3.4x throughput improvement with near-zero human intervention during execution.

### 3.2 Gen 2: Multi-Agent Orchestra (Feb 9-16)

Three AI agents coordinated by a Python orchestrator:

| Agent | Strengths | Fatal Flaws |
|-------|-----------|-------------|
| **Codex** (OpenAI `gpt-5.3-codex-spark`) | By far the fastest and most reliable for code interpretation and implementation. 15-25s triage, cheap, high success rate on single-file fixes | Linux sandbox on Windows — can't run MSBuild, PowerShell, or COM references. `--full-auto` maps to `sandbox: read-only` on Windows. Only workaround: `--dangerously-bypass-approvals-and-sandbox`. Also wiped the entire local repo once via `git clean -fdx` |
| **Gemini** (`gemini-3-pro-preview`) | Strong at bulk implementation — 466/852 CS8618 nullable warnings fixed in a single session | Probably capable, but rate limits make it unusable. Paid tier limits nearly identical to free tier. Workspace sandbox restricts file access to CWD only. `gemini-2.5-flash` was fast but superficial. `gemini-3.1-pro` returned 404 in API. Days of integration work for a model we can barely use |
| **Claude** (`claude-sonnet-4-6`) | Most reliable for implementation, no practical rate limits | Most expensive. Opus (5x cost) as fallback |
| **Claude Opus** (`claude-opus-4-6`) | Far better suited for supervision and orchestration — more prudent, efficient, clear. Conveys a confidence in problem management that Sonnet doesn't. The right model for reviewing, planning, and deciding, not just coding | Too expensive for routine implementation. Best used as the "brain" overseeing cheaper "hands" |

**The double-pay problem:** Sonnet fails → retry with Opus = paying twice for the same issue. This pattern accounted for **27% of total API spend**.

**Rate limit amnesia:** Without persistent tracking, every orchestrator restart wasted 40+ minutes trying agents that were still rate-limited.

### 3.3 Gen 3: The 31-Hour Disaster (Feb 17) — The Post-Mortem That Changed Everything

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

### 3.4 Gen 4: Self-Healing Supervisor + Adaptive Model Selection (Feb 18-28) — What Worked

The architecture that actually produced results:

```
orchestrator_supervisor.py (~800 lines)
  | monitors heartbeat (30s), manages 12 failure modes
  |
  +---> iis_orchestrator.py (~6,100 lines)
        | sync -> triage -> implement -> verify -> commit
        |
        +---> Codex Spark (primary -- fastest, cheapest, 86% success rate)
        |       +---> Claude Sonnet -> Opus (escalation chain)
        |
        +---> Independent Verification (no AI -- deterministic)
              1. build.ps1 (MSBuild)
              2. run-tests-core.sh (5,963 tests, 9 groups)
              3. git commit (green) OR git restore (red)
```

**The Feb 27 session — Codex-only, 104 issues:** The most productive single session used Codex Spark exclusively. 89/104 issues resolved (86%), 87 on the first attempt with no escalation. Only 4 issues (#1796, #1822 — RDP edge cases) resisted after 4 retries. Zero Claude or Gemini involvement. This contradicted our earlier assumption that Claude was the most reliable — Codex was faster, cheaper, and had a higher success rate when the orchestrator fed it correct context.

**12 failure modes handled automatically (FM1-FM12):**

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
| FM11 | No progress | 0 commits in 60 min or issue stuck >30 min | Progressive strikes (warn -> kill -> hard kill) |
| FM12 | Build infra failure | 3+ consecutive build failures (DLL locked, AV, disk) | Kill MSBuild, test build, conditional restart |

**Key design decisions:**
- **Test-fix-first:** Instead of immediately reverting on test failure, the AI gets 2 attempts to fix the failing test — recovering work that would otherwise be discarded
- **Circuit breaker:** 5 consecutive failures → verify baseline → stop if infrastructure is broken
- **Phantom detection:** 3 layers — PowerShell exit codes (97-99), Python validation, JSON sanity check
- **Persistent rate-limit tracking:** Saves 40+ min/session by instantly skipping blocked agents
- **Chain context reuse:** Each agent in the escalation chain receives previous agents' failed attempts as context

---

## 4. Cost Analysis

*Brief summary. Full details: [COST_ANALYSIS.md](COST_ANALYSIS.md)*

### 4.1 Total Spend

Approximately **$320** in AI API costs over the entire project (four generations, ~3 weeks).

### 4.2 Cost by Task Type

| Task | Avg. cost/call | Notes |
|------|---------------|-------|
| Triage | ~$0.20 | Cheap — not worth optimizing |
| Implementation | ~$1.68 | Bulk of the spend |
| Test fix | ~$1.75 | Similar to implementation |

### 4.3 Cost by Model

| Model | % of total spend | Role |
|-------|-----------------|------|
| Claude Opus | 58% | Most reliable, most expensive |
| Gemini Pro | 24% | Bulk implementation (Gen 2) |
| Codex Spark | 18% | Fast triage |

### 4.4 Where Money Was Wasted

- **Double-pay (Sonnet→Opus):** 27% of total — the single biggest waste category
- **Failed issues:** 10% — issues that consumed API calls but produced no commit
- **Pre-analysis phase:** <1% (disabled after proving ineffective)

### 4.5 Learning Curve — Cost per Commit

| Day | $/commit | Why |
|-----|----------|-----|
| Day 1 | $4.02 | No persistent rate tracking, no circuit breaker, Opus overuse |
| Day 4 | $1.49 | Codex functional, persistent tracking, chain context reuse |

### 4.6 Output Token Economics

**Output tokens = 97% of cost.** Output tokens cost 5x input tokens. The output/input ratio was 4:1. Every verbose explanation an AI agent writes is burning money.

### 4.7 Bottom Line

Only max-tier subscriptions with the best models produce cost-effective results. Intermediate tiers (Gemini Pro with near-free-tier limits, Codex with usage resets) generate retry overhead that erases the savings. The stabilized cost of ~$1.50/commit is comparable to a junior developer's hourly rate — but the orchestrator works 24/7.

---

## 5. Results

### 5.1 Issue Resolution

- **697 issues addressed** out of 843 tracked (83%), 1,365+ commits
- **5,963 tests** (up from 2,179 at v1.79.0), 0 failures
- **5,247 analyzer warnings → 0** across 100+ files

### 5.2 Codex Spark Session (Feb 27)

89/104 issues resolved (86%), 87 on first attempt — the most productive single session. Zero Claude or Gemini involvement. Confirmed that a single fast model with good context outperforms a complex multi-model chain.

### 5.3 Self-Healing Supervisor

12 failure modes handled automatically — zero human babysitting. Hundreds of manual interventions avoided across the project.

### 5.4 Success Patterns

- **Test-fix-first:** 2 fix attempts before revert — recovers work that would otherwise be lost
- **Circuit breaker:** 5 consecutive failures → baseline check → stop if infrastructure is broken
- **Phantom detection:** 3-layer validation eliminated false-positive test runs entirely
- **Persistent rate tracking:** 40+ min/session saved by instant skip of blocked agents
- **Chain context reuse:** each escalation carries previous attempts → fewer repeated mistakes
- **Cost stabilization:** $4.02/commit (day 1) → $1.49/commit (day 4)

### 5.5 Code Quality

**SonarCloud Quality Gate pass (Mar 2):**
- 6 security vulnerabilities fixed
- 50 hotspots reviewed
- 4-level code quality pipeline operational
- Coverage 80.7% on new code (Quality Gate threshold met)
- 1.6% duplication
- All 6 conditions green
- Reliability A, Security A, Maintainability A

**Analyzer warnings eliminated (5,247 → 0):**

| Phase | What was done | Count fixed |
|-------|---------------|-------------|
| **Autofix** | CA1507 `nameof`, CA1822 `static`, CA1805 defaults, CA1510 `ThrowIfNull`, CA2263 generics, CA1825 `Array.Empty` | ~1,300 |
| **String comparisons** | MA0006 `string.Equals`, CA1309/CA1310 `StringComparison`, CA1304 `IFormatProvider`, MA0074 overloads | ~400 |
| **Collection safety** | MA0002 `StringComparer` on Dictionary/HashSet, MA0015/MA0016 enum comparison | ~350 |
| **Misc fixes** | CA1806, CA2201, CA1069, CA1305, CA1872, CA1850, CA1869, CA2249, RCS1075 | ~200 |
| **Suppressed** | 46 architectural/legacy rules demoted in `.editorconfig` (CA1711, CA5351, MA0062, etc.) | ~3,000 |

### 5.6 Upstream PR Backports

4 upstream copilot PRs reviewed and applied:
- **#3177** — URL scheme injection fix (ProgramRoot, HelpMenu, UpdateWindow)
- **#3176** — AD Protected Users RDP auth (skip password for RestrictedAdmin/RCG)
- **#3154** — VNC Caps Lock fix (patch KeyTranslationTable)
- **#3171 (partial)** — RDP resize thread safety (UI thread marshaling)

### 5.7 SQL Schema Fix

6 missing columns in `tblExternalTools` (Hidden, AuthType, AuthUsername, AuthPassword, PrivateKeyFile, Passphrase) — schema v3.2 → v3.3 migration added.

---

## 6. Discussion — 12 Key Insights

### Insight 1: Automated tests are necessary but NOT sufficient

Focus handling, save/load round-trips, COM lifecycle, and settings persistence cannot be fully covered by unit tests. Manual testing remains irreplaceable for UX validation.

### Insight 2: AI agents add unsolicited "features"

Event handlers, `Focus()` calls, save logic that didn't exist — AI models optimize for "completeness" and will add code that wasn't requested. This is their most dangerous behavior.

### Insight 3: Retries are the dominant cost driver, not model price

The cheapest model that succeeds on the first attempt (Codex Spark, 86% success rate) outperforms expensive models that require escalation. Intermediate tiers with rate limits generate retry overhead that erases their per-token savings. The optimal strategy is: cheapest reliable model first, expensive model only on escalation.

### Insight 4: Simplicity beats complexity

3-agent orchestra (Gen 2) → 1 primary agent with fallback (Gen 4). The Feb 27 Codex-only session (89/104 issues, 86% success, zero escalation to other models) proved that a single fast model with good context outperforms a complex multi-model chain.

### Insight 5: Different models for different roles

Codex Spark is the most cost-effective for implementation — 86% success rate, fastest median (274s), cheapest per issue. Opus is the right choice for supervision, planning, and decision-making — prudent, efficient, and clear in a way that inspires confidence. Sonnet is the workhorse for complex multi-file changes. Gemini is probably capable but rate limits make it practically unusable. The optimal architecture is Opus as the "brain" orchestrating Spark as the primary "hands," with Sonnet as fallback for issues Spark can't resolve.

### Insight 6: Human oversight remains essential

7 regressions out of 585 issues is ~1.2% — but one of them (PuTTY root save) would silently destroy all user connections. Percentages don't capture severity.

### Insight 7: Self-healing beats manual monitoring

The supervisor eliminated 24/7 babysitting. 12 failure modes x multiple occurrences each = hundreds of manual interventions avoided.

### Insight 8: AI agents will destroy your local repo

Codex wiped the entire local clone with `git clean -fdx`. Push after every commit. Keep a cold backup clone. Treat local state as ephemeral — if it's not pushed, it doesn't exist.

### Insight 9: SonarCloud free plan coverage threshold is achievable with targeted effort

The default "Sonar way" Quality Gate requires 80% coverage on new code. Initially seemed unreachable for legacy WinForms (started at 51.2%), but a combination of targeted tests for testable business logic (160 new tests) and `sonar.coverage.exclusions` for genuinely untestable code (Protocol/COM/UI implementations) brought coverage to 80.7%. Custom Quality Gates cannot be assigned on free plans, but the default gate is achievable with discipline.

### Insight 10: Fork CI does not equal upstream PR checks

When contributing to an upstream repo, the SonarCloud check on the PR runs under the upstream's organization, not the fork's. All configuration effort on the fork's SonarCloud instance (custom gates, coverage tuning, hotspot reviews) is invisible to the PR Quality Gate. The fork's SonarCloud is useful for internal quality monitoring but has zero effect on upstream PR acceptance.

### Insight 11: .NET coverage tooling has silent failure modes

`dotnet test` with `--collect:"XPlat Code Coverage"` silently ignores the flag when given a DLL path instead of a csproj. No error, no warning, no output file. This cost 4 iterations to diagnose. The fix (`dotnet-coverage` tool) works at the CLR instrumentation level, bypassing MSBuild's data collector injection entirely. This should be the default approach for any project where `dotnet test` runs against pre-built DLLs.

### Insight 12: SonarCloud S2068 tracks by line position, not semantics

Renaming a variable from `passwordAttributeReplacement` to `sanitized` does not close the S2068 issue — SonarCloud re-detects it at the same line if the surrounding context still suggests credential handling. Only `// NOSONAR` on the exact flagged line reliably suppresses false positives.

---

## 7. Threats to Validity

### 7.1 Internal Validity (Selection Bias)

The orchestrator processes issues in priority order, likely resolving easier issues first. The 83% resolution rate may overstate effectiveness on hard issues — the remaining 17% includes architecturally complex problems (NUnit parallelization, COM lifecycle) that may be fundamentally beyond current AI capabilities.

### 7.2 External Validity (Single Project, N=1)

All results come from one legacy WinForms/.NET codebase. Projects with different tech stacks (web, mobile, microservices), languages, or issue distributions may yield different results. The 86% Codex success rate is specific to this codebase's issue profile.

### 7.3 Construct Validity (Single Developer)

One human developer performed all oversight, review, and manual testing. Different reviewers might catch different regressions or make different triage decisions. The 1.2% regression rate reflects this specific reviewer's thoroughness.

### 7.4 Reliability (Model Versioning)

AI model capabilities change with provider updates. Codex Spark's 86% success rate and timing data are specific to `gpt-5.3-codex-spark` as of February 2026. Future model versions may perform differently. Rate limits and pricing also change without notice.

### 7.5 Measurement Validity

"Resolved" includes issues classified as `testing` (195) — these have committed fixes but no manual verification. The true fix rate may be lower if manual testing reveals issues.

---

## 8. Operational Rules — Added After Failures

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

## 9. Performance Data — Real Data from 220 Measurements

*Raw timing data from `_timeout_history.json` across 220 agent invocations. Full analysis: [data/model_performance.md](data/model_performance.md)*

| Model | Task | n | Median | p80 | sigma | Range | <10s | >600s |
|-------|------|---|--------|-----|-------|-------|------|-------|
| **Codex Spark** | implement | 50 | 274s* | 544s | 279s | 5-769s | 34% | 12% |
| **Claude Sonnet** | implement | 50 | 474s | 630s | 218s | 106-918s | 0% | 24% |
| **Claude Sonnet** | triage | 50 | 12s | 16s | 4s | 5-21s | 34% | 0% |
| **Gemini Pro** | implement | 50 | 417s | 566s | 163s | 178-982s | 0% | 12% |
| **Gemini Pro** | triage | 50 | 47s | 72s | 27s | 18-100s | 0% | 0% |
| **GPT-4.1** | triage | 20 | 2.1s | 2.4s | 0.3s | 1.4-2.6s | 100% | 0% |

*Codex has a bimodal distribution (sigma=279s, highest of all models): 17/50 under 10s (Spark xHigh resolves instantly with median 7.4s), remaining 33 in the 200-770s range (Codex regular). This makes Codex the fastest overall (274s median vs 417-474s for Gemini/Claude) despite high variance. Gemini Pro has the most consistent implementation times (sigma=163s).

### 9.1 Key Observations from Production

- **Feb 27 session — Codex alone resolved 89/104 issues (86%)**, 87 on first attempt. The most productive single session used zero Claude or Gemini. Codex Spark was the most cost-effective model by a wide margin.
- **Spark xHigh:** 0% test failures when given correct context — the most reliable model for single-file fixes.
- **Opus:** 120-240s per task but far more prudent and efficient — conveys confidence in problem management that Sonnet doesn't. Best suited for supervision and review, not routine implementation.
- **Timeout management** was probably the hardest engineering problem in the orchestrator. Adaptive timeouts (60-1200s) with 1.3x escalation factor, yet models still timed out frequently.
- **93 escalations tracked** (54 implementation + 39 triage) in the timeout history. Separately, the Feb 27 Codex-only session needed only 17/104 retries — confirming that a single reliable model with good context beats a multi-model chain.

---

## 10. Failure Catalog — What Didn't Work

### 10.1 AI Agent Sandbox Limitations

- Codex on Windows: Linux sandbox cannot run PowerShell, MSBuild, or COM references — the three things this project requires
- Gemini workspace sandbox: file access restricted to CWD — can't read solution-level files
- Gemini rate limits: paid tier with limits nearly identical to free tier
- GPT-4.1: `workspace-write` fails entirely on Windows

### 10.2 The 31-Hour Disaster (Detailed in Section 3.3)

- 201 phantom test runs accepted as passing
- 353.7% pass rate accepted without question
- 3 concurrent orchestrator instances with garbled output
- BitDefender quarantine after 247 build cycles

### 10.3 AI-Introduced Regressions

7 AI-introduced regressions that passed ALL 5,963 automated tests (beta.5):

| Regression | Severity | What the AI did | Why tests didn't catch it |
|------------|----------|----------------|--------------------------|
| PuTTY root destroying confCons.xml | **Critical** | Added save logic for read-only PuTTY session imports | Save/load round-trip wasn't tested end-to-end |
| COM RCW crashes | **High** | Disposed ActiveX control already detached | COM lifecycle is inherently hard to unit test |
| Tab close hang | **High** | Dispose sequence wrong for disconnected connections | Tests don't simulate disconnected COM objects |
| Portable settings -> %AppData% | **High** | Missing `PORTABLE` define in some configurations | Settings path depends on build configuration |
| .NET 10 SettingsProvider | **Medium** | Framework change broke attribute-based resolution | Requires runtime .NET 10 behavior |
| Phantom tabs on tree click | **Medium** | Added preview-on-select as unsolicited "feature" | No test for "clicking tree doesn't open tabs" |
| Focus stealing on tab switch | **Low** | Added `ActivateConnection` on `SelectedIndexChanged` | Focus behavior requires real window interaction |

### 10.4 SonarCloud Quality Gate Failure (beta.5 PR #3188)

Codex attempted to fix Sonar issues but introduced 2 CRITICAL bugs + 1 BLOCKER — incorrect method inlining, bypassed property flow, incomplete Dispose pattern.

### 10.5 SonarCloud Configuration — 12 Hours of Platform Limitations (beta.6 PR #3189)

Getting the Quality Gate to pass required 10 iterations across four independent systems (SonarCloud API, GitHub Actions, .NET coverage tooling, upstream vs fork analysis). Key lessons learned:

1. **`dotnet test` with DLL path silently ignores `--collect` flags** — no error, no warning, no output file. The `dotnet-coverage` tool (CLR-level instrumentation) is the only reliable approach for projects that build with MSBuild but test with DLL paths.
2. **SonarCloud free plan blocks Quality Gate assignment** despite the API advertising `associateProjects: true`. Custom gates can be created and conditions deleted, but `qualitygates/select` fails with an undocumented organization-level restriction.
3. **Fork SonarCloud does not equal upstream PR SonarCloud.** PR checks run under the upstream's organization and Quality Gate. Three hours were spent optimizing the wrong SonarCloud instance before discovering this. All fork-side configuration is invisible to upstream PR acceptance.
4. **S2068 tracks by line position, not semantics.** Variable renames don't close the issue — only `// NOSONAR` on the exact flagged line works reliably.

Detailed troubleshooting log with all 10 iterations: [`EVIDENCE.md`](EVIDENCE.md)

### 10.6 Parallelization Attempts (Days of Work, Zero Success)

- **NUnit `[assembly: Parallelizable]`**: 27 failures from race conditions on shared mutable singletons (`DefaultConnectionInheritance.Instance`, `Runtime.EncryptionKey`, `Runtime.ConnectionsService`). Every attempt to make singletons thread-safe cascaded into more failures. Abandoned after 3 days — multi-process isolation is the only viable approach.
- **MSBuild `-m` scaling**: With only 3 projects in the solution, parallelism maxes out at ~4 effective cores regardless of CPU. The 587-file main project is the bottleneck — Roslyn parallelizes file compilation internally but there's no way to split a single project across build agents.
- **Concurrent orchestrator agents**: Running 2+ AI agents in parallel on the same repo caused git conflicts, garbled test output, and file locks. Tried worktrees, separate clones, and output directory isolation — all failed on Windows due to MSBuild file locking and shared COM registration. Serial execution remains the only reliable approach.

### 10.7 Codex Deleted the Entire Local Repository (Feb 27)

- Codex agent ran `git clean -fdx` followed by operations that wiped all untracked and ignored files — including build outputs, local configs, and uncommitted work
- Everything since the last `git push` was lost permanently. Hours of local-only changes, test configurations, and debugging notes — gone
- **Lesson learned the hard way:** Push early, push often. Local repo is NOT a backup. The orchestrator now pushes after every successful commit, not in batches. And we keep a second clone as cold backup.

### 10.8 Infrastructure Pitfalls

- `subprocess.run(timeout=T)` on Windows: hangs indefinitely when child processes inherit pipe handles
- PowerShell 5.1: Unicode em-dash corrupts the parser at a completely unrelated `}`
- `dotnet build` fails with COM references (`MSB4803`) — must use full MSBuild

---

## 11. Conclusion

### 11.1 Hypothesis Confirmed

**H1 is confirmed** on all three dimensions:
- Resolution rate: **83%** > 50% threshold
- Regression rate: **1.2%** < 2% threshold
- Cost per commit: **$1.49** (stabilized) < $5 threshold

### 11.2 Key Contribution

A reproducible model for legacy codebase maintenance using supervised AI orchestration. The model consists of:
- A self-healing supervisor monitoring the orchestrator
- An orchestrator coordinating AI agents through triage → implement → verify → commit
- Independent (non-AI) verification via build and test
- Operational rules injected into agent prompts, derived from observed failures
- Human oversight at PR review and manual testing gates

### 11.3 Generalizability

The approach is not specific to mRemoteNG. Any project with:
- A backlog of open issues (the "work queue")
- A test suite (the "verification oracle")
- A build system (the "compilation gate")

could benefit from the same model. The orchestrator code is ~6,900 lines of Python — not trivial, but not a research project either.

### 11.4 Economics

The economics make it viable: ~$1.50/commit, 24/7 operation, no burnout, no context switching. This is complementary to human developers, not a replacement — humans set direction, review output, and handle the 30% that AI cannot.

### 11.5 Future Work: Gen 5 (Opus Supervisor, Spark Executor)

The Gen 5 concept: **Opus as permanent supervisor, Spark as executor.**

The orchestrator monitors new issues (from upstream sync or user reports), triages autonomously, implements with Spark/Sonnet, and presents completed work for human approval. The rules from Section 8 are injected into every agent prompt — hard-won knowledge that prevents the same mistakes.

**Target state:** Autonomous maintenance with human intervention only at PR review. The orchestrator handles the "what" and "how," humans verify the "should we."

---

## References

See [RELATED_WORK.md](RELATED_WORK.md) for related work and full references.

### Project Artifacts

- Repository: [robertpopa22/mRemoteNG](https://github.com/robertpopa22/mRemoteNG) (fork)
- Upstream: [mRemoteNG/mRemoteNG](https://github.com/mRemoteNG/mRemoteNG)
- Upstream PR: [#3189](https://github.com/mRemoteNG/mRemoteNG/pull/3189) (release/1.81 → v1.78.2-dev)
- SonarCloud: [Dashboard](https://sonarcloud.io/project/overview?id=robertpopa22_mRemoteNG)
- Evidence trail: [`EVIDENCE.md`](EVIDENCE.md)

---

*Note: This paper has not yet undergone peer review. Data and interpretations are preliminary.*
