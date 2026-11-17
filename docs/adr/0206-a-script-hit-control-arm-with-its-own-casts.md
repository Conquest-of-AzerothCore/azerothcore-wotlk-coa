# 0206. A script-hit control arm with its own casts

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0160 (script-cast hits)

## Context

`script_hit` controls a hit by leaving the tooltip spell unknown in the control arm. Three claims have no such
control, because the spell is itself the cast that sets the hit off: Crusader's Brand 300513 (claim 18, 573020 on a
branded attacker), Divine Charge 527023 (claim 102, the trample 527269) and Argent Blade 807268 (claim 387, the
Scourgebane strike 801832).

## Considered options

1. No control arm. The proof gate needs one.
2. A control arm that makes other casts (or none), with the spell known in both arms. Chosen.

## Decision

`script_hit` takes `control_casts`: the control arm casts them instead of `casts`, and the spell is learned before the
control arm. Equal `casts` and `control_casts` are refused. The contract, the rule and the judge's control note name
the control casts (`control_text`).

## Consequences

- 18: the striker's Light of the Naaru takes 573020 only when branded. 387: Righteous Lunge unleashes no strike.
  102: no Divine Charge, no trample.
- Entries without the field regenerate byte-identical (1693 of 1693 for ADRs 0204-0208 together, 11 new scenarios).
- Tests: `test_behaviours.ScriptHitControlCastTests`.
