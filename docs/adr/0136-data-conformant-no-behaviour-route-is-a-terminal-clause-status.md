# 0136. "Data conformant, no behaviour route" is a terminal clause status

- Status: accepted
- Date: 2026-11-11

## Context

Batch 1 chunk 1 left two clauses data conformant because no behaviour route was built: Blessed Padding 301311's
area damage reduction and Lorescribe 804927's Libram cooldown reduction (`lean/batch1-c1-clock.md`). The owner ruled
on 2026-11-11 (`owner-rulings-2026-11-10.md`, "Batch 1 chunk 1 rulings"): a clause that only a data check can verify,
because no behaviour route exists, gets a terminal status "data conformant, no behaviour route", with the reason
written; it needs a second agent's attempt to build a route first; such clauses leave the remaining work. The tool
gap of ADR 0127 is the nearest status, but it applies to an unproven clause and an owner acceptance can replace the
second attempt.

## Considered options

1. Reuse `tool_gap` for data conformant clauses. Rejected: a tool gap counts as resolved and keeps an unproven clause
   unproven; the terminal status counts as closed, not resolved, and the clause is data conformant.
2. A ledger field `no_behaviour_route` with ADR 0127's reason and attempts, two different agents required, its own
   coverage column. Chosen.

## Decision

- `coverage.NO_BEHAVIOUR_ROUTE` (`no_behaviour_route`): `{"reason", "attempts": [{"agent", "report"}]}` on a claim
  entry, validated like a tool gap (`require_attempts`), refused beside a `tool_gap`.
- `no_route_state`: `terminal` when the clause is data conformant and two distinct agents attempted a route,
  `pending` with one agent, `not_data` when the clause is unproven or behaviour proven.
- `ClauseCoverage.no_routes`, `terminal_no_route` and `open_data`; `clause_coverage_lines` prints the terminal count
  and the open data count as their own lines; fragment rows carry the declaration and its state.

## Consequences

- Proven, behaviour, data and resolved figures do not change: a terminal clause is still data conformant.
- No Templar ledger entry declares the status yet; the chunk 2 route agent writes the first ones.
- Seeded test:
  `test_coverage.NoBehaviourRouteTest.test_seeded_one_agent_keeps_the_clause_open_and_a_second_agent_closes_it`
  (closed with one agent when `MIN_NO_ROUTE_AGENTS` is patched to 1).
