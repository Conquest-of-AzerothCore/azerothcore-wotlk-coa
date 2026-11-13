# 0076. A `charge_recharge` behaviour kind for native spell-charge count and recharge timing

- Status: accepted
- Date: 2026-11-10

## Context

Temple Guardian's tooltip (803792) states "3 Charges" and "35 sec recharge" as two of its clauses. Neither is
proven by any existing verdict: the batch only measures the heal formula, power cost and `hit_mean`. Spell.dbc's
own fields for 803792 carry no charge data at all (`ProcCharges` 0, `RecoveryTime` 0, `Category` 0;
`coa-dbc-viewer record --table Spell --id 803792`). The actual numbers come from a separate, class-agnostic
client-DBC system: `SpellCharges.dbc` (row `Spell=803792 Category=251`) and `SpellChargesCategory.dbc` (row
`ID=251 MaxCharges=3 RecoveryTime=35000`), applied unconditionally to every spell with such a row by
`ApplyClientSpellCharges` (`src/server/coa/AscensionClassMechanics.cpp:1082-1096`), which sets
`SpellInfo::MaxCharges`/`ChargeRecoveryTime`/`ChargeCategoryId`. `Player::GetSpellCharges`/`HasSpellCooldown`
(`src/server/game/Entities/Player/Player.cpp:17592, 17651-17666`) read those fields generically to gate casts and
restore one charge per elapsed recovery interval — no Templar script is involved anywhere in this path, so this
is squarely a class-agnostic tool capability, not a Templar-specific one.

No existing behaviour kind models a repeated-cast-until-exhausted sequence, an over-cast refusal, or a
recharge-window bracket. The harness already exposes the right native metrics (`spell_charges`, `cast_failure`)
and a ready precedent for "charge to an ally, relocate between casts" (`attempt_fixtures`/`cast_steps` in
`triggers.py`, used by this file's own 804571/705256/705298 entries), but none of those compose into a single
pass/fail judge for "N charges, recharge in T ms".

## Considered options

1. Model this as a `metric_delta` (before/after a single learn). Rejected: there is nothing to learn or unlearn
   here — the clause is about repeated-cast behaviour and a timed recovery, not a before/after passive comparison.
2. Hand-write a one-off scenario (as the orphaned, never-executed
   `apps/coa-gameplay-test/scenarios/hero-templars-slash-charges-6568.json` pattern does for a different class)
   with the expected values baked into `assert equals/within_ms` steps inside the JSON. Rejected: the hard rule
   requires expected values to live in Python/the class file, not inside hand-authored scenario JSON, so a seeded
   wrong-value unit test could not target the real judge logic; it would also not generalize to the next
   charge-bearing spell.
3. Add a new `charge_recharge` behaviour kind: the scenario builder spends `max_charges` casts one at a time
   (relocating between casts when the spell closes distance, exactly as the existing trigger entries already
   do), snapshots `spell_charges` after each cast and after a refused over-cast attempt, snapshots `cast_failure`
   for that refusal, then brackets `recharge_ms` at a configurable `+-tolerance` (default 5%, the owner's
   standing numeric tolerance) with one snapshot just before the window and one just after. All expected values
   (`max_charges`, `recharge_ms`) live in the class file; the judge in `compare.py` computes the full expected
   sequence in Python and compares it to the measured snapshots. Chosen.

## Decision

- `behaviours.py` gains `BEHAVIOUR_CHARGE_RECHARGE`, the `charge_recharge` kind, `ChargeRechargeSpec`,
  `charge_recharge_scenario` and `charge_recharge_spec`, dispatched from `behaviour_scenario` like every other
  kind. The scenario accepts `target` of `caster`, `target` or `ally` (803792 uses `ally`) and reuses
  `cast_interval` (native `StartRecoveryTime`/cast time, class-agnostic) for cast spacing.
- `compare.py` gains `behaviour_charge_recharge_verdict`, dispatched from `judge_behaviour`. It checks, from raw
  snapshot values only: the starting charge count equals `max_charges`; each of the `max_charges` casts leaves
  one fewer charge; an over-cast attempt leaves the count at 0 and is refused (`cast_failure` nonzero); the count
  is still 0 just before `recharge_ms * (1 - tolerance)`; and exactly 1 charge is available by
  `recharge_ms * (1 + tolerance)`.
- `classes/templar.json` gets one new `charge_recharge` entry for 803792 (`max_charges: 3`, `recharge_ms: 35000`,
  `target: "ally"`), citing the DBC rows and the generic C++ path above in `observe_source`.

## Consequences

- Any other charge-bearing spell (Templar's own or another class's) gets this proof with a four-field class-file
  entry and no new tool code; the tolerance default matches the owner's standing 5%-on-numbers rule without a
  per-entry override unless a clause needs a tighter or looser bracket.
- The over-cast refusal check doubles as a server-defect detector: if a future regression let a fourth cast
  silently consume a charge (going negative) or skip the refusal, this judge reports `alert` rather than passing
  silently, which the kind's own seeded-wrong-value unit test exercises directly.
