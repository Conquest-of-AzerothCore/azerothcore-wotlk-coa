# 0148. Remove the Templar per-level credit list

- Status: accepted (mentor approval, 2026-11-11); verification after the build pending
- Date: 2026-11-11
- Supersedes: the credit part of ADR 0045 (`CreditStockEffectRealPointsPerLevelRemainder` and
  `TEMPLAR_TOOLTIP_FULL_SCALED_BY_LEVEL_SPELLS`). ADR 0045's cancel-list arithmetic stays in force.

## Context

ADR 0045 added a credit for 5 Templar ranks, later 15 (cf351abcf2). The credit adds back the fraction that stock
`SpellEffectInfo::CalcValue` loses when it truncates `level x RealPointsPerLevel` before the sum
(SpellInfo.cpp:497). The only evidence was our own conformance check and a debug log on our own server; no player
report, live log or owner decision was cited, and the ten later ranks were added on DBC shape alone
(`lean/adr0045-review.md`).

The owner then ruled (option (a), `owner-rulings-2026-11-10.md`, "Per-level truncation", 2026-11-11) that this early
truncation is known engine rounding for all 21 classes, with no server change, and ADR 0147 judges it in the tool.
The list therefore compensates an accepted engine rounding for 15 of the 71 Templar spells with such a term, and does
nothing at level 60 on the top ranks 503141 and 578276. The mentor approved its removal ("ADR 0045 list removal",
2026-11-11).

## Considered options

1. Keep the list. Rejected: it contradicts option (a) and is inconsistent across the class.
2. Extend the list to every Templar effect. Rejected: the same contradiction, on more spells.
3. Remove the list and its credit, and keep the rest of ADR 0045. Chosen.

## Decision

- Remove `TEMPLAR_TOOLTIP_FULL_SCALED_BY_LEVEL_SPELLS`, `CreditStockEffectRealPointsPerLevelRemainder` and its call in
  `ModifySpellEffectBaseValue` (`src/server/coa/AscensionTemplarContracts.cpp`).
- Keep what came with 6043ce8c8c through the shared helper: `StockEffectRealPointsPerLevelAmount`, the cancel list
  `TEMPLAR_TOOLTIP_UNSCALED_BY_LEVEL_SPELLS` with 804150 folded in, and `CancelStockEffectRealPointsPerLevel`
  subtracting `float(int32(continuous))`. Those ranks' tooltips show no per-level term at all; that is a different
  mismatch, not this rounding.

## Consequences

- At the reference character's stats, 11 of the 15 ranks read 1 lower on every roll (503135, 503136, 503137, 503139,
  803157, 803373-803378). Their `effect_value` verdicts move from the tooltip range to ADR 0147's known engine
  rounding, with the engine range as evidence. 503138, 503140, 503141 and 578276 do not change.
- Two ledger clauses are re-judged: Chastise "blasting an enemy for ${$m1+0+$sph*0.6+$AP*0.45} Holy damage" and
  Benediction "restoring ${$m2+0+$STA*0.25+$SP*0.3} health to an ally, scaling with Stamina".
- The hit scenarios of 503141 and 578276 and the 11 hand-written scenarios that name these ranks do not move.
- A read the engine computation does not explain stops the verification and goes to the mentor.
