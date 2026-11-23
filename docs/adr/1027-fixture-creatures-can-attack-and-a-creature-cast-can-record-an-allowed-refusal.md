# 1027. Fixture creatures can attack and a creature cast can record an allowed refusal

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 0606 (after_trigger_steps)

## Context

Claims about what an enemy does under a debuff need the enemy to act (cycle 10 proposal "enemy actions in the
harness"):

- Amphibimorph 500952 "making them unable to attack" (aura 60 sets `UNIT_FLAG_PACIFIED`): nothing makes a fixture
  creature melee the caster; the `attack` action is the player's own swing (tool note T-b13-9).
- Eye of Kimbul 503714 "While affected, enemies cannot stealth or turn invisible.": the fixed server refuses the marked
  creature's stealth cast, and the harness creature cast fails the scenario on any refusal
  (`Require(result == SPELL_CAST_OK)`), so the two cycle 8 entries were held (tool note T2, pitfall 8).

## Decision

- Harness (`CoAGameplayTest.cpp` `Act`, `run.py`): action `creature_attack` (a creature actor and a `target`: react
  state aggressive, `CreatureAI::AttackStart`, then `Unit::Attack` if the AI did not engage; the step fails unless the
  target is the victim; `stop: true` stops the melee and sets the creature passive). The creature `cast` accepts
  `allowed_refusal` (a `SpellCastResult`): the step also passes when the cast is refused with exactly that code. Every
  creature cast records its result, read by `creature_cast_result` (creature actor, `spell`; -1 before any cast, SPELL_CAST_OK 255 for a cast that started).
- Two `metric_delta` option modules: `target_attack_window` (the dummy melees the caster from the control phase; each
  judged reading counts its swings over the window, from a snapshot) and `refusable_target_casts` (dummy casts after
  each trigger with an allowed refusal, their results read; a refused control cast is unmeasured).
- Witch Doctor entries: `500952 frog_pacified` (at least 2 swings in the control window, 0 under the frog) and the
  held `503714 no_stealth` and `no_invisibility` (refusal 22 allowed).
- Not built: a creature cast at an ally while the dummy is the claim's target (Fool's Play 681007 mirror, War Golem
  800330 redirect) needs generator reads of a spell landing on an owned creature, and a crit-forced enemy striker
  beside an effigy (706542) needs a forcing that aura 290 (-100% crit, additive) can cancel; both stay tool gaps.

## Consequences

- New action, field, metric and options only; a creature cast without `allowed_refusal` still fails on any refusal.
  Generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical; class 13 gains three
  scenarios.
- Catalog scenario `witch-doctor-harness-enemy-actors.json`: an allowed refusal recorded as 22 against an unmarked
  control, and a creature's swings while attacking and after it stops.
- Seeded tests in `metric_delta_options/test_target_attack_window.py` and `test_refusable_target_casts.py`.
