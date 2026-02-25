# mRemoteNG - Build & Development Notes

> **Parent:** [../CLAUDE.md](../CLAUDE.md) (Gestime Ecosystem — reguli universale)

## Automated Agent Notice

If you are running as an automated agent via `claude -p`:
- Your ONLY job is to fix the specific issue described in your prompt
- Do NOT run `iis_orchestrator.py`, `sync`, `analyze`, `update`, or any orchestrator commands
- Do NOT read or modify files in `.project-roadmap/` — no JSON files, no scripts, no plans
- Do NOT run `git commit`, `git add`, `git push` — the orchestrator handles all commits
- Focus ONLY on source code in `mRemoteNG/`, `mRemoteNGTests/`, `mRemoteNGSpecs/`

## Repository Structure
- **Origin (fork):** `robertpopa22/mRemoteNG`
- **Upstream (official):** `mRemoteNG/mRemoteNG`
- **Main branch:** `main` — active development (v1.81.0-beta.2)
- **Solution:** `mRemoteNG.sln` (.NET 10, SDK-style projects with COM references)

## Build Instructions

**Do NOT use `dotnet build`** — fails with `MSB4803` on COM references (`MSTSCLib` RDP ActiveX control). Must use full VS BuildTools MSBuild.

### Commands:
```powershell
# Full build (restore + compile):
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\github\mRemoteNG\build.ps1"

# Fast incremental (skip restore):
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\github\mRemoteNG\build.ps1" -NoRestore

# Self-contained (embeds .NET runtime, output: bin\x64\Release\win-x64-sc\):
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\github\mRemoteNG\build.ps1" -SelfContained
```

`build.ps1` auto-detects VS installation (VS2026 > VS2022). Self-contained uses `-t:Publish` and restore MUST include `/p:PublishReadyToRun=true` (NETSDK1094).

## Testing

### Run tests (preferred):
```powershell
# Headless (CI/orchestrator):
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\github\mRemoteNG\run-tests.ps1" -Headless

# Skip build (fast iteration):
pwsh -NoProfile -ExecutionPolicy Bypass -File "D:\github\mRemoteNG\run-tests.ps1" -Headless -NoBuild

# Bash runner (fastest, no build):
bash run-tests-core.sh
```

### Single test group:
```bash
dotnet test "mRemoteNGTests/bin/x64/Release/mRemoteNGTests.dll" --results-directory /tmp/mrt --verbosity normal --filter "FullyQualifiedName~mRemoteNGTests.Tools"
```

### Critical Rules:
- **`--verbosity normal` ONLY** — minimal/quiet crashes testhost on .NET 10
- **`--results-directory` outside repo** — TestResults inside repo causes cascading crashes
- **DLL path, not .csproj** — `dotnet test --no-build` on .csproj looks in wrong `bin\Release\`
- **No interactive tests** — NEVER create tests with GUI dialogs, message boxes, or user input. Mock all UI dependencies.
- **No `[assembly: Parallelizable]`** — causes race conditions on shared mutable singletons
- **RunWithMessagePump pattern** — for ObjectListView/FrmOptions tests, use `Application.Run(form)` + `Application.ExitThread()` in finally

### The Golden Rule (test failures):
Every test failure MUST be resolved before finishing a task. NO EXCEPTIONS.
1. **Fix the code** if the test caught a real bug
2. **Fix the test** if the test logic is flawed
3. **Remove the test** ONLY if no longer valid
**NEVER use `[Ignore]`** for failing tests.

### 100% DLL Coverage:
`run-tests.ps1` runs parallel groups + sequential Remnants. If coverage gap detected, exit 96. New namespaces: update `$groups` in `run-tests.ps1` or let Remnants handle them.

### Current status: 2927/2927 passed, 0 failed

## CI/CD
- Runners: `windows-2025-vs2026` with MSBuild 18.x (VS2026)
- Workflows: `pr_validation.yml` (build), `Build_mR-NB.yml` (release)
- Platforms: x86, x64, ARM64
- Code signing: SignPath Foundation (mandatory — see `CODE_SIGNING_POLICY.md`)
- Version: read from `mRemoteNG/mRemoteNG.csproj` `<Version>` element

## Branch Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Active development — default branch |
| `release/X.Y` | Historical release branches (frozen) |

### Feature branch naming:
| Prefix | When | Example |
|--------|------|---------|
| `fix/<issue>-<desc>` | Bug fix | `fix/2735-rdp-smartsize-focus` |
| `feat/<issue>-<desc>` | New feature | `feat/1634-protocol-token` |
| `security/<desc>` | Security | `security/ldap-sanitizer` |
| `chore/<desc>` | Infra, deps, CI | `chore/sqlclient-sni-runtime` |

Lowercase, kebab-case, max 50 chars after prefix. No tool prefixes.

### Sync upstream:
```bash
git fetch upstream && git merge upstream/v1.78.2-dev
```

## Session Discipline — Build Verification

1. **Run build before ending session** — especially for multi-file changes
2. If build fails, fix BEFORE reporting progress
3. **Never leave uncompilable code** — worse than slower progress
4. Prefer small verified steps over massive unverified refactoring

## Developer Guide

For orchestrator operations, release checklists, IIS system, issue tracking,
PR history, and release status, see: **`.project-roadmap/DEVELOPER_GUIDE.md`**
