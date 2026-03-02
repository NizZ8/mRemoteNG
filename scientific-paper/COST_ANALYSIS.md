# Cost Analysis — AI-Assisted Software Maintenance

## Overview

| Metric | Value |
|--------|-------|
| Total spend | ~$320 over 4 weeks (Feb 8 - Mar 2, 2026) |
| Total commits | 1,365+ |
| Stabilized cost | $1.49/commit (day 4 onwards) |
| Analysis tool | `cost_analysis.py` (12-section report against orchestrator logs) |

## Cost by Task Type

| Task | Avg. cost/call | Notes |
|------|---------------|-------|
| Triage | ~$0.20 | Cheap — not worth optimizing |
| Implementation | ~$1.68 | Bulk of the spend |
| Test fix | ~$1.75 | Similar to implementation |

Triage is a negligible cost driver at $0.20/call. Implementation and test-fix tasks are virtually identical in cost (~$1.70), which makes sense — both require the AI to read code, understand context, and produce working modifications.

## Cost by Model

| Model | % of total spend | Role |
|-------|-----------------|------|
| Claude Opus | 58% | Most reliable, most expensive |
| Gemini Pro | 24% | Bulk implementation (Gen 2 era) |
| Codex Spark | 18% | Fast triage + primary implementation (Gen 4) |

Claude Opus dominated the spend at 58% despite being used primarily as an escalation target. This is the direct consequence of the double-pay problem (see Waste Categories below). Gemini Pro's 24% share came almost entirely from the Gen 2 multi-agent era before rate limits made it impractical. Codex Spark's 18% share is disproportionately productive — it resolved 89/104 issues in the Feb 27 session alone.

## Waste Categories

| Category | % of total | Root cause |
|----------|-----------|------------|
| Double-pay (Sonnet->Opus escalation) | 27% | The single biggest waste. Sonnet fails -> retry with Opus = paying twice for the same issue. Eliminated in Gen 4 by making Codex Spark the primary model |
| Failed issues | 10% | Issues that consumed API calls but produced no commit. Includes architectural problems beyond AI capability and infrastructure failures |
| Pre-analysis phase | <1% | Experimental phase where AI analyzed issues before attempting fixes. Disabled after proving ineffective — direct implementation with test verification is faster and cheaper |

**Total waste: ~38% of spend.** The remaining 62% produced the 1,365+ commits. Reducing waste further requires either better first-attempt success rates or eliminating the escalation chain entirely (which the Feb 27 Codex-only session proved viable).

## Learning Curve

| Day | $/commit | What changed |
|-----|----------|-------------|
| Day 1 | $4.02 | No persistent rate tracking, no circuit breaker, Opus overuse. Every orchestrator restart burned 40+ minutes retrying rate-limited agents. No escalation chain — expensive models used for everything |
| Day 4 | $1.49 | Codex Spark functional as primary model, persistent rate-limit tracking across sessions, chain context reuse (each escalation carries previous attempts), circuit breaker prevents infinite retry loops |

Note: Days 2-3 data was not captured at sufficient granularity to report individual data points. The transition from $4.02 to $1.49 was driven by three discrete improvements: (1) persistent rate-limit file, (2) Codex Spark as primary executor, and (3) chain context reuse reducing repeated mistakes in escalation.

## Output Token Economics

| Metric | Value |
|--------|-------|
| Output tokens as % of cost | 97% |
| Output vs input token price | 5x (output costs 5x input) |
| Output/input ratio | 4:1 (AI produces 4x more tokens than it reads) |

**Implication:** Verbose AI explanations are the primary cost driver. Every "Let me explain what I found..." or "Here's a summary of the changes..." burns money at 5x the input rate. The orchestrator's agent prompts now include explicit instructions: "No narration. No summaries. No repeating. Fix, don't explain."

This finding led to the `CLAUDE.md` rule: "Output Efficiency (CRITICAL — output tokens are 97% of API cost)" with specific prohibitions against narration, summaries, and unnecessary comments.

## Comparison with Human Development

| Dimension | AI Orchestrator | Human Developer |
|-----------|----------------|-----------------|
| Cost per commit | $1.49 | Variable (hourly rate / commits) |
| Operating hours | 24/7 | ~8 hours/day |
| Context switching | Zero | Significant overhead |
| Burnout | None | Real constraint |
| Regression rate | 1.2% (7/585) | Varies |
| Issues handled autonomously | 86% (Codex Feb 27 session) | 100% (but slower) |
| Issues requiring human | ~30% (architectural, COM, UX) | 0% |

**Bottom line from README:** "Only max-tier subscriptions with the best models produce cost-effective results. Intermediate tiers (Gemini Pro with near-free-tier limits, Codex with usage resets) generate retry overhead that erases the savings. The stabilized cost of ~$1.50/commit is comparable to a junior developer's hourly rate — but the orchestrator works 24/7."

The relationship is complementary, not replacement. Humans set direction, review output, and handle the 30% that AI cannot (COM lifecycle, multi-step UX flows, architectural decisions). The orchestrator handles the "what" and "how," humans verify the "should we."

## Cost Optimization Recommendations (Derived from Data)

1. **Use the cheapest model that succeeds on first attempt.** Codex Spark at 86% success rate and 18% of spend outperformed all other models on cost-effectiveness.
2. **Eliminate the escalation chain when possible.** The Feb 27 Codex-only session (89/104 issues, zero escalation) was the most productive and cheapest session.
3. **Enforce output brevity in agent prompts.** Output tokens are 97% of cost — every unnecessary word costs 5x.
4. **Persist rate-limit state across sessions.** Saves 40+ minutes per session by instantly skipping blocked agents.
5. **Invest in first-attempt success.** Better context (chain context reuse) and better prompts reduce retries, which are the dominant cost driver.
