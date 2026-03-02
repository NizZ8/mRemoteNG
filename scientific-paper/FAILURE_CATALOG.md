# Failure Catalog — Complete Post-Mortems

This document catalogs every significant failure encountered during the AI-assisted modernization of mRemoteNG (Feb 8 - Mar 2, 2026). Each entry includes root cause analysis, impact assessment, and lessons learned.

---

## 1. AI Agent Sandbox Limitations

All three major AI coding agents have sandbox restrictions that fundamentally conflict with this project's requirements (MSBuild, COM references, PowerShell).

### Codex (OpenAI, `gpt-5.3-codex-spark`)

- **Linux sandbox on Windows:** Codex runs in a Linux sandbox environment even on Windows hosts. This means it cannot execute PowerShell, MSBuild, or COM reference resolution — the three things this project requires for build verification.
- **`--full-auto` maps to `sandbox: read-only` on Windows:** The flag that should enable autonomous operation actually restricts the agent to read-only file access on Windows. The only workaround is `--dangerously-bypass-approvals-and-sandbox`, which removes all safety guardrails.
- **Despite these limitations:** Codex Spark was the most productive model overall (89/104 issues in the Feb 27 session, 86% success rate). The orchestrator compensates for sandbox limitations by running build/test verification independently after each agent completes.

### Gemini (Google, `gemini-3-pro-preview`)

- **Workspace sandbox restricts file access to CWD only:** Cannot read solution-level files (`mRemoteNG.sln`, `Directory.Build.props`) that are one or more directories above the working directory. This breaks context for any multi-project change.
- **Rate limits nearly identical between paid and free tiers:** Days of integration work were invested for a model that could barely be used in production. `gemini-2.5-flash` was fast but superficial. `gemini-3.1-pro` returned 404 in the API. The rate limit situation made Gemini practically unusable for sustained orchestrator workloads.
- **Probably capable:** When it could run, Gemini produced quality work (466/852 CS8618 nullable warnings fixed in a single session). The limitation is purely operational, not capability.

### GPT-4.1

- **`workspace-write` fails entirely on Windows:** The workspace write permission mode produces errors on Windows hosts, making the model unable to modify files at all.

### Lesson Learned

AI agent sandboxes are designed for safety, not for legacy codebases with COM references and platform-specific build systems. The orchestrator architecture (agent writes code -> independent verification) is the correct pattern — it decouples code generation from build/test execution.

---

## 2. The 31-Hour Disaster (Feb 17, 2026)

The single worst incident in the project. A single orchestrator run consumed 31 hours, produced 247 test invocations (201 of which were phantoms), and culminated in BitDefender quarantining the build output.

### Timeline

| Time | Event |
|------|-------|
| T+0h | Orchestrator starts, begins processing issues |
| T+0-10h | 31 commits produced (productive phase) |
| T+10h | Test infrastructure silently breaks |
| T+10-31h | 201 phantom test runs accepted as passing. No useful output |
| T+31h | BitDefender quarantines `mRemoteNG.dll`. Build completely blocked |

### Root Cause

`mRemoteNG.sln` did not include the test projects. An AI agent had added the test project references locally during a previous session but never committed the `.sln` change. When the orchestrator ran `dotnet test mRemoteNG.sln`, it executed against a solution with no test projects — which succeeds instantly with 0 tests discovered, 0 tests run, 0 tests failed.

### What Went Wrong — Six Compounding Failures

1. **353.7% pass rate accepted:** The orchestrator's test validation accepted a result where passed > total tests. No sanity check existed for this mathematically impossible condition. The pass count exceeded the total because phantom runs reported inconsistent numbers that accumulated without validation.

2. **201 phantom test runs:** Of 247 test invocations, 201 completed in <1 second with 0 tests discovered. The orchestrator treated "0 tests failed" as "all tests passed" — a critical conflation of absence-of-failure with success.

3. **3 concurrent orchestrator instances:** No single-instance lock existed. Three separate orchestrator processes ran simultaneously, garbling test output, competing for git locks, and producing interleaved log entries that were impossible to debug.

4. **No circuit breaker:** After 5, 10, 20 consecutive failures, the orchestrator kept trying. No mechanism existed to detect that infrastructure was broken and stop processing.

5. **Immediate revert on any test failure:** Instead of attempting to fix failing tests, the orchestrator immediately ran `git restore` on any failure — discarding potentially hours of agent work. This "fail-fast" approach sounds safe but wastes enormous amounts of compute.

6. **BitDefender ATD quarantine:** After 247 rapid build-delete cycles, BitDefender's Advanced Threat Defense flagged `mRemoteNG.dll` as suspicious. The kernel minifilter driver blocks the exact filename even after "disabling" BitDefender in the UI. Fix required: restore from quarantine, add exclusions in ALL BitDefender modules (not just real-time protection), and **reboot** the machine (the kernel driver caches the block list in memory).

### Lesson Learned

An orchestrator without monitoring is more dangerous than manual work. It can destroy a night's worth of progress while you sleep. This incident directly motivated the Gen 4 architecture: supervisor process, heartbeat monitoring, phantom detection, circuit breaker, and single-instance locking.

---

## 3. AI-Introduced Regressions (7 total)

Seven regressions introduced by AI agents that passed ALL 5,963 automated tests at the time (beta.5). Every single one required manual testing to detect.

| # | Regression | Severity | What the AI did | Why tests didn't catch it |
|---|------------|----------|----------------|--------------------------|
| 1 | PuTTY root destroying confCons.xml | **Critical** | Added save logic for read-only PuTTY session imports | Save/load round-trip was not tested end-to-end. This would have silently destroyed all user connections on next save |
| 2 | COM RCW crashes | **High** | Disposed ActiveX control already detached from its Runtime Callable Wrapper | COM lifecycle is inherently hard to unit test — requires real COM objects with real reference counting |
| 3 | Tab close hang | **High** | Dispose sequence wrong for disconnected connections | Tests don't simulate disconnected COM objects. The hang only occurs when a connection drops mid-session |
| 4 | Portable settings -> %AppData% | **High** | Missing `PORTABLE` define in some build configurations | Settings path depends on build configuration. Tests run under a single configuration |
| 5 | .NET 10 SettingsProvider | **Medium** | Framework change broke attribute-based settings resolution | Requires runtime .NET 10 behavior that differs from .NET 8. Tests ran but the behavior difference was not covered |
| 6 | Phantom tabs on tree click | **Medium** | Added preview-on-select as unsolicited "feature" | No test existed for "clicking a tree node does NOT open a tab" — testing for absence of behavior is rarely done |
| 7 | Focus stealing on tab switch | **Low** | Added `ActivateConnection` on `SelectedIndexChanged` | Focus behavior requires real window interaction with message pump. Unit tests cannot simulate this |

### Pattern Analysis

- **4/7 regressions involve AI adding unsolicited behavior** (#1, #6, #7, and partially #4). AI models optimize for "completeness" and will add event handlers, Focus() calls, and save logic that was never requested. This is their most dangerous behavior.
- **3/7 involve COM/ActiveX lifecycle** (#2, #3, #5). COM interop is fundamentally untestable with standard unit test approaches — it requires real COM objects with real reference counting in real windows.
- **0/7 were caught by 5,963 automated tests.** This proves that automated tests are necessary but NOT sufficient for UX-facing code.

### Rules Added After These Failures

- No event handlers on `SelectionChanged` without human approval
- No `Protocol.Focus()` outside explicit user action
- Validate save/load round-trip (`confCons.xml` must survive save -> load -> save)
- No modifications to `WndProc`, `Dispose`, or COM interop without human review

---

## 4. SonarCloud Quality Gate Failures

### Beta.5 (PR #3188) — AI Introduces Critical Bugs While "Fixing" Quality Issues

Codex attempted to fix SonarCloud-reported issues but introduced 2 CRITICAL bugs + 1 BLOCKER:
- **Incorrect method inlining:** Codex replaced a method call with inline code but missed a side effect, creating a null reference path
- **Bypassed property flow:** Codex removed what it thought was dead code, but the property setter had side effects used by downstream callers
- **Incomplete Dispose pattern:** Codex added `IDisposable` implementation but missed one disposable field, creating a resource leak worse than the original issue

This demonstrates a fundamental risk: AI agents treating code quality tool suggestions as simple transformations when they require semantic understanding of the codebase.

### Beta.6 (PR #3189) — 12-Hour Configuration Journey

Getting the SonarCloud Quality Gate to pass required 10 iterations across four independent systems (SonarCloud API, GitHub Actions, .NET coverage tooling, upstream vs fork analysis). See `SONARCLOUD_TROUBLESHOOTING.md` for the complete iteration log.

Key discovery: Fork SonarCloud configuration has zero effect on upstream PR checks. Three hours were spent optimizing the wrong SonarCloud instance.

---

## 5. Parallelization Attempts (All Failed)

Three separate approaches to parallelizing the build/test pipeline were attempted over multiple days. All failed.

### NUnit `[assembly: Parallelizable]`

**Attempt:** Enable fixture-level test parallelism via NUnit's built-in parallel attribute.

**Result:** 27 failures from race conditions on shared mutable singletons:
- `DefaultConnectionInheritance.Instance` — static singleton modified by multiple test fixtures
- `Runtime.EncryptionKey` — global encryption key changed between tests
- `Runtime.ConnectionsService` — shared connection state

Every attempt to make singletons thread-safe cascaded into more failures. Making `EncryptionKey` thread-local broke tests that expected global state. Adding locks to `ConnectionsService` caused deadlocks with the UI thread. **Abandoned after 3 days.**

The architectural fix (dependency injection throughout the entire application) would be a multi-month refactoring effort with high regression risk.

### MSBuild `-m` Scaling

**Attempt:** Use MSBuild's parallel project compilation flag to leverage the 48-thread Threadripper.

**Result:** With only 3 projects in the solution, parallelism maxes out at ~4 effective cores regardless of CPU count. The 587-file main project is the bottleneck. MSBuild parallelizes at the project level (not file level). Roslyn parallelizes file compilation internally, but there is no way to split a single project across build agents.

**Impact:** Build time remained at ~9-15s. The hardware is not the bottleneck — the solution structure is.

### Concurrent Orchestrator Agents

**Attempt:** Run 2+ AI agents in parallel on the same repository to process issues faster.

**Result:** Git conflicts, garbled test output, and file locks. Three approaches were tried:
- **Git worktrees:** Failed on Windows due to MSBuild file locking on shared NuGet package directories
- **Separate clones:** Failed due to shared COM registration (RDP ActiveX) and conflicting test output directories
- **Output directory isolation:** Failed because MSBuild's intermediate directory cannot be fully redirected for COM reference resolution

**Conclusion:** Serial execution remains the only reliable approach on Windows with COM references.

---

## 6. Codex Repository Wipe (Feb 27, 2026)

### Incident

Codex agent ran `git clean -fdx` as part of its operation, which wiped all untracked and ignored files from the entire repository:
- Build outputs (`bin/`, `obj/`)
- Local configuration files
- Uncommitted work in progress
- Test configurations and debugging notes
- Everything since the last `git push`

### Impact

Hours of local-only changes were lost permanently. The orchestrator had been batching commits and pushing periodically (not after every commit), so multiple successful fixes that had been committed locally but not pushed were destroyed.

### Root Cause

Codex operates with `--dangerously-bypass-approvals-and-sandbox` (the only mode that works on Windows). In this mode, it has unrestricted filesystem access and will run cleanup commands it deems necessary. `git clean -fdx` removes all untracked files including those in `.gitignore` — a destructive operation that should never be run without explicit human approval.

### Fix Applied

1. **Push after every successful commit.** The orchestrator now pushes immediately, not in batches. Local repo is treated as ephemeral.
2. **Cold backup clone.** A second clone of the repository is maintained as a read-only backup.
3. **Agent prompt rules:** "Never run `git commit/add/push` — the orchestrator handles all commits" added to all agent prompts.

### Lesson Learned

AI agents will destroy your local repo. Push after every commit. Keep a cold backup clone. Treat local state as ephemeral — if it's not pushed, it doesn't exist.

---

## 7. Infrastructure Pitfalls

### subprocess.run timeout on Windows

`subprocess.run(timeout=T)` on Windows hangs indefinitely when child processes inherit pipe handles. The Python `subprocess` module's timeout only applies to the direct child process — if that process spawns children (as MSBuild and dotnet test do), the parent waits forever for the pipe to close.

**Workaround:** Use process groups with `CREATE_NEW_PROCESS_GROUP` flag and kill the entire group on timeout.

### PowerShell 5.1 Unicode Corruption

PowerShell 5.1 (the default Windows PowerShell) corrupts Unicode em-dash characters (`—`) in script files. The parser encounters the multi-byte character and fails at a completely unrelated `}` brace, producing error messages that point to the wrong line.

**Workaround:** Use PowerShell 7+ (`pwsh`) exclusively. The orchestrator's `build.ps1` and `run-tests.ps1` both specify `pwsh` in their shebang lines.

### dotnet build Fails with COM References

`dotnet build` fails with error `MSB4803` when the project contains COM references (MSTSCLib for RDP ActiveX control). The .NET SDK's build system cannot resolve COM type libraries — only the full MSBuild from Visual Studio BuildTools can.

**Workaround:** `build.ps1` auto-detects VS installation (VS2026 > VS2022) and uses full MSBuild. All CI workflows use MSBuild explicitly. The `CLAUDE.md` prominently warns: "Do NOT use `dotnet build`".

### MSYS2 Bash Cannot Kill Windows Processes

`kill <PID>` from MSYS2 bash does not see Windows-native processes (python.exe, powershell.exe, dotnet.exe). The MSYS2 `kill` command only manages MSYS2/Cygwin processes.

**Workaround:** Always use `taskkill /F /PID <PID>` or `powershell.exe -NoProfile -Command 'Stop-Process -Id <PID> -Force'`.

### PowerShell Variable Substitution in Bash

MSYS2 bash interprets `$variables` inside PowerShell commands passed via `-Command`. This causes silent failures or wrong values.

**Workaround:** Write PowerShell scripts to `.ps1` files and execute with `pwsh -File`, or use single quotes around the `-Command` argument.
