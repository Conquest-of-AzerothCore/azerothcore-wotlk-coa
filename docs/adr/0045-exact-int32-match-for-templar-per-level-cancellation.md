# 0045. Match stock's int32 rounding when cancelling or crediting Templar per-level scaling

- Status: accepted
- Date: 2026-11-09

## Context

Round 8 (`round8/server-findings-scaling.md`) and round 5 before it found seven Templar `effect_value`
verdicts (503135, 503136, 801446, 801463, 803157, 803373, 803374) with small, persistent negative
deviations (roughly -1.2 to -1.9 points), several flipping between alert and ok across identical reruns.
Both rounds bounded a *single* final `int32(value)` truncation of `SpellEffectInfo::CalcValue`'s
accumulated float to `(-1, 0]` and found several deviations exceeded that bound, leaving the cause
"not established".

Round 9 instrumented `AscensionTemplarContracts.cpp`'s `ModifySpellEffectBaseValue` hook directly (a
temporary `LOG_ERROR` tagged with the caster's GUID, removed before this commit) and read the exact
inputs and outputs of a live cast for all seven ranks. The measurements show stock `CalcValue`
(`src/server/game/Spells/SpellInfo.cpp:474-493`) performs **two** separate `int32` truncations, not one:

1. `basePoints += int32(level * basePointsPerLevel);` — folds the per-level scaling term into the
   roll's base points as an early, separate truncation, before this CoA script hook ever runs and before
   the random die roll is even added.
2. `return int32(value);` — the final truncation of the accumulated float (roll + AP/SP/STA bonus), the
   one both earlier rounds already accounted for via the checker's `TRUNCATED_READ` widening.

`CancelStockEffectRealPointsPerLevel` (added for the 14 spells round 8 confirmed, including 801446) and
the bespoke `804150` correction both cancel the per-level term by subtracting the *continuous* float
value (`level * perLevel`), not the *int32-truncated* amount stock actually added. The difference between
the two is the residual: for 801446 at the test caster's clamped level this is -0.9 per cast, every cast,
deterministically — not sampling noise, and not previously covered by the single-truncation bound because
it is a second, independent truncation site. For 503135, 503136, 803157, 803373 and 803374 — ranks whose
tooltip reading keeps the full continuous per-level scaling (no cancellation code touches them at all) —
stock's truncation of that scaling (losing up to just under 1 point) stacks with the final value's own
truncation, together exceeding the single-truncation bound round 5/8 checked against.

## Decision

Introduce one shared helper, `StockEffectRealPointsPerLevelAmount`, computing the continuous per-level
term with the same level/`MaxLevel`/`BaseLevel`/`SpellLevel` clamp stock `CalcValue` uses. Two call sites
use it:

- `CancelStockEffectRealPointsPerLevel` (unchanged list membership, now also covering `804150`, whose
  bespoke subtraction is removed in favour of the shared, correctly-rounded one) now subtracts
  `float(int32(continuous))` — exactly what stock already added — instead of the continuous float.
- A new `CreditStockEffectRealPointsPerLevelRemainder`, applied to `503135`, `503136`, `803157` (effect 0)
  and `803373`/`803374` (effect 1), adds back `continuous - float(int32(continuous))`: the fraction stock's
  own early truncation discarded, so the final value matches the tooltip's continuous reading up to the
  single, already-modelled final truncation.

No change to `compare.py`'s judging, bands or `TRUNCATED_READ` allowance: this is a server-side fix, not a
check change, and the ADR/unit-test requirement for widening a tolerance does not apply.

## Verification

Two independent `--gameplay-clock simulated` runs in `/home/fab/Projects/coa-wt-r9-roll-margin`: all seven
targeted `effect_value` verdicts (`conformance-templar-value-{503135,503136,801446,801463,803157,803373,
803374}`) read `ok` on both runs, comfortably inside their bands (for example 803157: measured 153.03/152.94
against band [152.59, 153.86], versus the pre-fix mean of ~151.95-152.03 that sat outside it).

## Not in scope

`503137`-`503141` (siblings of 803157), `803375`-`803378` and `578276` (siblings of 803373/803374) carry
the same `EffectRealPointsPerLevel`/`MaxLevel` shape and are likely to carry the same residual, but none of
them was a reported alert this round; per the fix-scoped-to-the-report convention they are left untouched
and noted for whoever next reviews that family, rather than fixed speculatively here.
