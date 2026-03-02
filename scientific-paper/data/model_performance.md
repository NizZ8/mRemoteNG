# Model Performance Data — Raw Timing Statistics

> **Source:** `.project-roadmap/_timeout_history.json` (220 agent invocations)
> **Period:** February 8 – March 2, 2026

## Summary Table

| Model | Task | n | Median | p80 | σ | Range | <10s | >600s |
|-------|------|---|--------|-----|---|-------|------|-------|
| **Codex Spark** | implement | 50 | 274s | 544s | 279s | 5–769s | 34% | 12% |
| **Claude Sonnet** | implement | 50 | 474s | 630s | 218s | 106–918s | 0% | 24% |
| **Claude Sonnet** | triage | 50 | 12s | 16s | 4s | 5–21s | 34% | 0% |
| **Gemini Pro** | implement | 50 | 417s | 566s | 163s | 178–982s | 0% | 12% |
| **Gemini Pro** | triage | 50 | 47s | 72s | 27s | 18–100s | 0% | 0% |
| **GPT-4.1** | triage | 20 | 2.1s | 2.4s | 0.3s | 1.4–2.6s | 100% | 0% |

## Codex Spark Bimodal Distribution

Codex Spark shows the highest variance (σ=279s) due to a bimodal distribution:

- **Spark xHigh mode** (17/50 invocations): Median 7.4s, range 4.8–8.8s. Resolves instantly for simple single-file fixes. 0% test failures when given correct context.
- **Codex regular mode** (33/50 invocations): Range 189–769s. Standard implementation with full context processing.

This bimodality makes Codex the fastest overall (274s median vs 417–474s for Gemini/Claude) despite high variance.

## Key Observations

1. **Gemini Pro has the most consistent implementation times** (σ=163s, lowest among implementation models) but no invocations under 10s.

2. **Claude Sonnet has the highest >600s rate** (24%) — meaning nearly 1 in 4 implementation tasks exceeds 10 minutes. This drives up the p80 significantly.

3. **GPT-4.1 triage is near-instantaneous** (median 2.1s, σ=0.3s) but was deprecated during the study.

4. **Gemini Pro triage is 4x slower than Claude Sonnet triage** (47s vs 12s median) — surprising given Gemini's faster token generation speed. Likely due to prompt processing overhead in Gemini CLI.

5. **93 escalations tracked** in the timeout history: 54 implementation + 39 triage. The Feb 27 Codex-only session needed only 17/104 retries.

## Timeout Management

Adaptive timeouts were the hardest engineering problem in the orchestrator:
- Base timeout: 60s (triage), 300s (implementation)
- Escalation factor: 1.3x per retry
- Maximum: 1200s
- Models still timed out frequently despite adaptive adjustment

## Data Source

Raw data: `.project-roadmap/_timeout_history.json`

Each entry contains:
- `model`: AI model identifier
- `task_type`: "triage" or "implement"
- `duration_seconds`: wall-clock time
- `timestamp`: ISO 8601
- `success`: boolean
- `issue_id`: GitHub issue number

*Note: This data has not yet undergone independent peer review.*
