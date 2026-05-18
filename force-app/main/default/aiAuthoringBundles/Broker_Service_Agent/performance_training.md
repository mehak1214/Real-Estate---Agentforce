Agentforce Broker Performance - Training and Mapping

Purpose
- Teach the Broker_Service_Agent how to consume the Apex `PerformanceOutput` JSON and produce deterministic, human-friendly responses and UI cards.

Mapping
- Input JSON: the invocable returns an array of `PerformanceOutput` objects. Agent code should use the first element as the active performance record: `performance = response[0]`.

Fields of interest
- `performance.performancePeriod` — label for the period shown to the broker.
- `performance.monthlySalesCount` — integer count of unique sales.
- `performance.totalSalesAmount` — currency total (format in UI).
- `performance.createdLeads`, `performance.convertedLeads`, `performance.conversionRatio` — lead KPIs.
- `performance.paidCommission`, `performance.pendingCommission` — commission money values.
- `performance.ranking`, `performance.incentiveEligibility` — short strings for badge/cta.
- `performance.status`, `performance.message` — check status first; if not `Success`, return message as error.

Behavioral Rules (must-follow)
- Always check `performance.status` first. If != 'Success' then return the `performance.message` as user-visible error.
- Do not attempt to recompute top-level totals client-side; trust Apex-provided `totalSalesAmount`, `paidCommission`, and `pendingCommission`.
- Use `performance.performancePeriod` in every summary sentence.
- Format monetary values as localized currency.

Display Templates
- Summary card (compact):
  - Title: `{performance.performancePeriod}`
  - Line 1: `{performance.monthlySalesCount} sales • {performance.totalSalesAmount}`
  - Line 2: `{performance.ranking} • {performance.incentiveEligibility}`
- Detailed list:
  - `Created leads: {performance.createdLeads}`
  - `Converted leads: {performance.convertedLeads} ({performance.conversionRatio}%)`
  - `Paid commission: {performance.paidCommission}`
  - `Pending commission: {performance.pendingCommission}`

Example Training Pairs

- Example 1 (Success summary)
  - Input JSON: { "performancePeriod": "May 2026", "monthlySalesCount": 4, "totalSalesAmount": 1200000, "paidCommission": 5000, "pendingCommission": 1500, "ranking": "Rank #2", "incentiveEligibility": "Eligible", "status": "Success" }
  - Target utterance: "For May 2026 you have 4 sales totalling ₹1,200,000 (Rank #2). Paid commission ₹5,000, pending ₹1,500. You're Eligible for incentives. Would you like commission details?"

- Example 2 (Leads + conversion)
  - Input JSON: { "performancePeriod": "May 2026", "createdLeads": 10, "convertedLeads": 3, "conversionRatio": 30.00, "status": "Success" }
  - Target utterance: "You created 10 leads and converted 3 (30.00%). Want to see the converted opportunities?"

- Example 3 (Error)
  - Input JSON: { "status": "Error", "message": "No broker contact linked" }
  - Target utterance: "I couldn't find a broker profile for your user. Please contact your administrator to link your contact."

Implementation notes for authors
- Add these pairs to the agent's supervised training set and ensure the agent policy enforces the behavioral rules above.
- Provide UI rendering templates as shown; prefer numeric/currency formatting helpers provided by the runtime.

Verification
- After deploying Apex & agent bundle, call the invocable and verify the agent shows the summary card and produces sample utterances matching the examples.
