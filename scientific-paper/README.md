# Scientific Paper — AI-Assisted Legacy Software Maintenance

> A case study documenting the use of a multi-agent AI orchestrator to resolve
> 843 open issues on the mRemoteNG legacy WinForms/.NET codebase.

## Abstract

This study evaluates whether a supervised AI orchestrator can resolve a large backlog
of open issues on a legacy codebase. Applied to mRemoteNG (843 issues, 100K+ LOC,
.NET/WinForms with COM interop), the orchestrator coordinated three heterogeneous AI
agents (Codex Spark, Claude Sonnet/Opus, Gemini Pro) through four architectural
generations. Result: 697/843 issues addressed (83%), 1.2% regression rate, cost
stabilized at $1.49/commit. The approach is reproducible for any project with a test
suite and build system.

## Documents

| Document | Description |
|----------|-------------|
| [**PAPER.md**](PAPER.md) | Main research document — start here |
| [METHODOLOGY.md](METHODOLOGY.md) | Formal methodology (population, instruments, metrics, baseline) |
| [RELATED_WORK.md](RELATED_WORK.md) | Related work — SWE-bench, Devin, Aider, AutoCodeRover, MetaGPT, etc. |
| [COST_ANALYSIS.md](COST_ANALYSIS.md) | Detailed cost breakdown (~$320 total, learning curve, waste categories) |
| [FAILURE_CATALOG.md](FAILURE_CATALOG.md) | Complete failure post-mortems (31-hour disaster, 7 regressions, sandbox limits) |
| [SONARCLOUD_TROUBLESHOOTING.md](SONARCLOUD_TROUBLESHOOTING.md) | 10-iteration SonarCloud Quality Gate troubleshooting log |
| [EVIDENCE.md](EVIDENCE.md) | Evidence trail with verifiable data points (git history, CI artifacts) |
| [data/model_performance.md](data/model_performance.md) | Model timing statistics (220 measurements, σ, range, bimodal analysis) |

## How to Read

1. Start with **PAPER.md** for the complete narrative
2. Refer to **METHODOLOGY.md** for formal research design
3. Dive into supporting documents for detailed data

## Data Sources

| Source | Location | Description |
|--------|----------|-------------|
| Git history | `git log` on this repository | Every code change with timestamps |
| Issue database | `.project-roadmap/issues-db/` (on `main` branch) | 843 issues as JSON |
| Orchestrator code | `.project-roadmap/scripts/iis_orchestrator.py` | ~6,100 LOC Python |
| Timing data | `.project-roadmap/_timeout_history.json` | 220 agent invocations |
| CI artifacts | [GitHub Actions](https://github.com/robertpopa22/mRemoteNG/actions) | Build/test logs |
| SonarCloud | [Dashboard](https://sonarcloud.io/project/overview?id=robertpopa22_mRemoteNG) | Quality metrics |

## Status

*This research has not yet undergone peer review. Data and interpretations are preliminary.*

**Period:** February 8 – March 2, 2026
**Author:** Robert Popa (human) + AI contributors (Claude, Codex, Gemini)
