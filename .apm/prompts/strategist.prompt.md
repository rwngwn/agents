---
description: Run the strategist — produce strategic bets, OKRs, PR/FAQ, and founding hypothesis
input:
  - idea: "Idea, product description, or discovery output"
argument-hint: "<idea-or-discovery-output>"
---

Delegate this work to the `strategist` agent with the host's native subagent
mechanism. Do not produce the strategy in the current agent.

Produce a full strategy document for the following idea or product.

If the user has provided discovery output (personas, journey maps, competitive landscape), use it to ground every strategic claim. If no discovery output is provided, synthesize your best understanding of the target users and market from the idea description alone — but flag explicitly that discovery was skipped.

**Input:**
`${input:idea}`

Produce the full strategy document covering:
- 2–3 strategic approaches with trade-offs and a recommendation
- OKRs (measurable, time-bound, grounded in user needs)
- PR/FAQ (press release from the future + hardest internal questions)
- Founding hypothesis (falsifiable, single sentence)

Follow the strategist output format precisely.
