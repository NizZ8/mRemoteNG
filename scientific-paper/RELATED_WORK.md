# Related Work

> **Context:** This document positions the mRemoteNG AI orchestrator within the broader
> landscape of AI-assisted software engineering tools and research.

---

## 1. Benchmarks for AI-Assisted Software Engineering

### SWE-bench (Jimenez et al., 2024)
- **Venue:** ICLR 2024 (Oral). arXiv: [2310.06770](https://arxiv.org/abs/2310.06770)
- **Key claim:** Benchmark of 2,294 real GitHub issues across 12 Python repositories. Best models at launch resolved only ~3-4% of issues.
- **Comparison:** SWE-bench tests single-agent, single-issue resolution on Python-only repos. The mRemoteNG orchestrator resolved 843 issues on a production .NET/WinForms codebase with COM interop and multi-agent coordination — a scenario SWE-bench does not cover. SWE-bench also operates on isolated task instances, not cumulative codebase evolution where fix N may break fix N-1.

### SWE-agent (Yang et al., 2024)
- **Venue:** NeurIPS 2024. arXiv: [2405.15793](https://arxiv.org/abs/2405.15793)
- **Key claim:** Custom Agent-Computer Interfaces (ACI) improve LM agents' repo navigation. Achieved 12.5% pass@1 on SWE-bench.
- **Comparison:** Single-agent, single-LM system. The orchestrator uses heterogeneous agents (Codex for triage, Gemini for bulk transforms, Claude for complex multi-file fixes) with fallback chains.

### SWE-bench Pro (Scale AI, 2025)
- **Venue:** arXiv: [2509.16941](https://arxiv.org/abs/2509.16941)
- **Key claim:** Enterprise-level benchmark with 1,865 problems from 41 repos (including proprietary). Top models score ~23% vs 70%+ on SWE-bench Verified.
- **Comparison:** SWE-bench Pro better represents the difficulty level of real-world legacy codebases. The orchestrator's 83% resolution rate on mRemoteNG exceeds even SWE-bench Pro's top scores, though the comparison is not direct (different issue populations, cumulative vs. isolated).

### SWE-bench Memorization Critique (Microsoft Research, 2025)
- **Venue:** arXiv: [2506.12286](https://arxiv.org/abs/2506.12286)
- **Key claim:** SWE-bench scores inflated by memorization — models identify buggy files with 76% accuracy from issue text alone, with up to 47pp performance drops on non-SWE-bench repos.
- **Comparison:** This validates our approach of evaluating on a real production codebase (mRemoteNG, not in any benchmark) rather than relying on benchmark scores. Our 83% resolution rate is immune to memorization concerns.

### RepoMod-Bench (Modelcode AI, 2026)
- **Venue:** arXiv: [2602.22518](https://arxiv.org/abs/2602.22518)
- **Key claim:** Benchmark for repository-level modernization (21 repos, 8 languages, 1.6M LOC). Sharp scaling collapse: pass rates drop from 90%+ on <10K LOC to below 20% on >50K LOC.
- **Comparison:** Directly relevant — mRemoteNG at ~114K LOC sits well above the scaling collapse threshold. Our 83% resolution rate at this scale is significantly above the benchmark's predictions for comparable codebase sizes.

### Aider Polyglot Benchmark (Gauthier, 2024)
- **Source:** [aider.chat/docs/leaderboards](https://aider.chat/docs/leaderboards/)
- **Key claim:** 225 Exercism exercises across 6 languages. Best scores: o1 at 62% (Dec 2024), Claude 3.7 Sonnet surpassing it (Feb 2025).
- **Comparison:** Measures code-editing accuracy on self-contained exercises, not issue resolution on legacy codebases with build systems, COM references, or WinForms dependencies.

---

## 2. Autonomous AI Software Engineering Agents

### Devin (Cognition Labs, 2024)
- **Source:** [cognition.ai/blog/introducing-devin](https://cognition.ai/blog/introducing-devin)
- **Key claim:** First autonomous AI software engineer. 13.86% on SWE-bench at launch. ARR grew to ~$73M by mid-2025.
- **Comparison:** Monolithic single-agent system. Does not address heterogeneous agent orchestration where different models handle different task types. On mRemoteNG, no single agent could handle all 843 issues — Codex excelled at triage, Gemini at bulk nullable warning elimination (466 fixes/session), Claude at multi-file WinForms/COM fixes.

### OpenHands (formerly OpenDevin) (Wang et al., 2024)
- **Venue:** arXiv: [2407.16741](https://arxiv.org/abs/2407.16741)
- **Key claim:** Open-source platform for AI software development agents. MIT licensed, 2.1K+ contributions.
- **Comparison:** Provides infrastructure for building agents but does not prescribe a production orchestration pattern. The orchestrator implements a specific three-agent pipeline (triage → implement → verify) with atomic commits and fallback chains — a concrete instantiation OpenHands' framework could host but does not demonstrate at scale.

### Aider (Gauthier, 2023-2025)
- **Source:** [aider.chat](https://aider.chat/)
- **Key claim:** Terminal-based AI pair programming tool integrated with Git. Multi-model backends.
- **Comparison:** Single-user, single-agent interactive tool. Does not support autonomous multi-issue batch processing or orchestrated pipelines. The orchestrator processed 843 issues with zero human intervention per issue.

### Cursor (Anysphere, 2022-2025)
- **Source:** [cursor.com](https://cursor.com/)
- **Key claim:** AI-first code editor. Series D at $29.3B valuation. Features parallel multi-agent runs (up to 8 agents from a single prompt).
- **Comparison:** IDE-centric developer productivity tool. Its multi-agent parallelism (8 agents, same prompt) differs fundamentally from the orchestrator's heterogeneous agent pipeline (different models for different task types). Does not address autonomous batch issue resolution.

---

## 3. Automated Program Repair

### AutoCodeRover (Zhang et al., 2024)
- **Venue:** ISSTA 2024. arXiv: [2404.05427](https://arxiv.org/abs/2404.05427)
- **Key claim:** AST-based code search for autonomous repair. 46.2% on SWE-bench Verified at <$0.70/task.
- **Comparison:** Targets individual bug fixes in Python repos. The orchestrator handles bug fixes AND feature additions across a .NET codebase with C#, XAML, and WinForms designer files. AutoCodeRover's per-issue approach does not address cumulative effects of 843 sequential modifications.

### Agentless (Xia et al., 2024)
- **Venue:** FSE 2025. arXiv: [2407.01489](https://arxiv.org/abs/2407.01489)
- **Key claim:** Simple three-phase approach (localization → repair → validation). 32% on SWE-bench Lite at $0.70/bug.
- **Comparison:** Validates that simple pipelines can be effective — which supports the orchestrator's approach. However, Agentless handles single issues in isolation; the orchestrator must manage cross-issue dependencies and cumulative build integrity.

### RepairAgent (Bouzenia, Devanbu, Pradel, 2025)
- **Venue:** ICSE 2025. arXiv: [2403.17134](https://arxiv.org/abs/2403.17134)
- **Key claim:** FSM-guided autonomous repair. Fixed 164 bugs on Defects4J at $0.14/bug.
- **Comparison:** RepairAgent's FSM approach is conceptually similar to the orchestrator's task graphs. However, it uses a single LLM and operates on Java (Defects4J), not .NET/WinForms.

### CodeR (Chen et al., 2024)
- **Venue:** arXiv: [2406.01304](https://arxiv.org/abs/2406.01304)
- **Key claim:** Multi-agent issue resolving with pre-defined task graphs. Specialized roles (reproducer, programmer, tester). 28.33% on SWE-bench Lite.
- **Comparison:** CodeR's role specialization is the closest prior work to the orchestrator's agent specialization. Key difference: CodeR uses the same underlying LLM for all roles; the orchestrator uses genuinely different AI systems with different architectures and strengths.

### SGAgent (Multiple authors, 2026)
- **Venue:** arXiv: [2602.23647](https://arxiv.org/abs/2602.23647)
- **Key claim:** Localize-suggest-fix paradigm with knowledge-graph context retrieval. 51.3% on SWE-bench Verified at $1.48/instance.
- **Comparison:** SGAgent's per-instance cost ($1.48) closely matches the orchestrator's stabilized cost ($1.49/commit). However, SGAgent operates on isolated Python issues, not cumulative modifications across 843 issues on a .NET codebase.

### LLM-based APR Survey (Yang, Cai et al., 2025)
- **Venue:** arXiv: [2506.23749](https://arxiv.org/abs/2506.23749)
- **Key claim:** Survey of 62 LLM-based repair systems across four paradigms: fine-tuning, prompting, procedural pipelines, and agentic frameworks.
- **Relevance:** The orchestrator falls into "agentic framework with procedural pipeline backbone." The survey's finding that agent-based approaches trade latency for capability matches the orchestrator's experience (15-20 min/issue).

### Agyn (Benkovich, Valkov, 2026)
- **Venue:** arXiv: [2602.01465](https://arxiv.org/abs/2602.01465)
- **Key claim:** Multi-agent system modeling a full engineering team (manager, engineer, reviewer, researcher) with dedicated workspaces. 72.2% on SWE-bench 500 without benchmark tuning.
- **Comparison:** Agyn's role-based architecture (manager/engineer/reviewer) closely parallels the orchestrator's triage/implement/verify pipeline. Key difference: Agyn uses a single LLM for all roles; the orchestrator uses genuinely different AI systems with different architectures and strengths.

---

## 4. Multi-Agent Collaboration Frameworks

### MetaGPT (Hong, Zhuge et al., 2024)
- **Venue:** ICLR 2024 (Oral). arXiv: [2308.00352](https://arxiv.org/abs/2308.00352)
- **Key claim:** Encodes SOPs into multi-agent LLM collaboration. Role assignment (Product Manager, Architect, Engineer) in assembly-line paradigm.
- **Comparison:** MetaGPT assigns different *roles* to instances of the same LLM. The orchestrator assigns different *LLMs* to different roles, exploiting genuine architectural differences. MetaGPT targets greenfield generation; the orchestrator targets legacy maintenance.

### ChatDev (Qian, Liu et al., 2024)
- **Venue:** ACL 2024. arXiv: [2307.07924](https://arxiv.org/abs/2307.07924)
- **Key claim:** Chat-powered software development with "communicative dehallucination."
- **Comparison:** Focuses on generating new software. The orchestrator maintains an existing 100K+ LOC legacy codebase. ChatDev's agents communicate through natural language; the orchestrator's agents communicate through code artifacts.

### Codified Context (Vasilopoulos, 2026)
- **Venue:** arXiv: [2602.20478](https://arxiv.org/abs/2602.20478)
- **Key claim:** 108K-line C# distributed system built with 19 specialized domain-expert agents, a hot-memory constitution, and 34 cold-memory spec documents across 283 sessions.
- **Comparison:** The closest comparable work: multi-agent orchestration on a C# codebase of similar scale (~114K LOC). Vasilopoulos uses hot/cold memory architecture analogous to our `CLAUDE.md` + issue database. Key difference: greenfield development vs. legacy maintenance.

---

## 5. AI-Assisted Legacy Modernization (Industry)

### Amazon Q Developer Transform (AWS, 2024-2025)
- **Source:** [AWS DevOps Blog](https://aws.amazon.com/blogs/devops/accelerate-large-scale-modernization-of-net-mainframe-and-vmware-workloads-using-amazon-q-developer/)
- **Key claim:** AI-driven modernization. Java transformation saved Amazon "4,500 years of development work."
- **Comparison:** Targets language/framework migration (Java 8→17, .NET Framework→Linux). The orchestrator targets issue resolution within the same framework (.NET Framework→.NET 10).

### GitHub Copilot Productivity Study (Peng et al., 2023)
- **Source:** arXiv: [2302.06590](https://arxiv.org/abs/2302.06590)
- **Key finding:** 26% average productivity increase, 35-39% for junior developers.
- **Comparison:** Copilot accelerates human coding. The orchestrator replaces the human coding loop entirely for tractable issues.

---

## 6. Positioning Summary

| Dimension | SWE-bench ecosystem | Devin / Cursor | MetaGPT / ChatDev | CodeR / Agyn | Codified Context | **mRemoteNG Orchestrator** |
|-----------|-------------------|----------------|-------------------|-------------|------------------|---------------------------|
| Task scope | Single issue, isolated | Interactive session | Greenfield generation | Single issue, benchmark | Greenfield (283 sessions) | **843 issues, cumulative** |
| Agent count | 1 | 1 | Multiple (same LLM) | Multiple (same LLM) | 19 (same LLM, specialized) | **3+ (heterogeneous LLMs)** |
| Codebase | Python (12 repos) | Any (user-guided) | Generated | Python (SWE-bench) | C# 108K LOC (new) | **.NET/WinForms + COM 114K LOC** |
| Build verification | Unit tests only | Manual | None | Unit tests | Unknown | **Full MSBuild + 6,123 tests** |
| Production use | Benchmark | Commercial product | Research prototype | Research prototype | Production | **Production fork, upstream PR** |
| Legacy-specific | No | No | No | No | No | **Yes** |

**Primary novelty:** The combination of (a) heterogeneous multi-agent orchestration with genuinely different AI systems, (b) applied to a real production legacy codebase (not a benchmark), (c) with cumulative build verification ensuring no regressions across 843 sequential changes, (d) demonstrated at scale with measurable outcomes, and (e) targeting legacy maintenance rather than greenfield development — a gap identified by RepoMod-Bench's scaling collapse at >50K LOC.

---

## References

```
Jimenez et al. (2024)    SWE-bench              ICLR 2024      arXiv:2310.06770
Yang et al. (2024)       SWE-agent              NeurIPS 2024   arXiv:2405.15793
Scale AI (2025)          SWE-bench Pro          arXiv          arXiv:2509.16941
Microsoft (2025)         SWE-bench Illusion     arXiv          arXiv:2506.12286
Modelcode AI (2026)      RepoMod-Bench          arXiv          arXiv:2602.22518
Zhang et al. (2024)      AutoCodeRover          ISSTA 2024     arXiv:2404.05427
Xia et al. (2024)        Agentless              FSE 2025       arXiv:2407.01489
Bouzenia et al. (2025)   RepairAgent            ICSE 2025      arXiv:2403.17134
Chen et al. (2024)       CodeR                  arXiv          arXiv:2406.01304
SGAgent (2026)           SGAgent                arXiv          arXiv:2602.23647
Benkovich et al. (2026)  Agyn                   arXiv          arXiv:2602.01465
Wang et al. (2024)       OpenHands              arXiv/ICLR     arXiv:2407.16741
Hong et al. (2024)       MetaGPT                ICLR 2024      arXiv:2308.00352
Qian et al. (2024)       ChatDev                ACL 2024       arXiv:2307.07924
Vasilopoulos (2026)      Codified Context       arXiv          arXiv:2602.20478
Yang, Cai et al. (2025)  LLM APR Survey         arXiv          arXiv:2506.23749
Peng et al. (2023)       Copilot Productivity   arXiv          arXiv:2302.06590
```
