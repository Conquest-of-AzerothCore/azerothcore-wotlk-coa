# 0086. `aggro_redirect` behaviour kind for taunt victim-switch clauses

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's `cast-conditions-cooldowns` workstream's own recommendation (step 9's report) named Absolution
800424's "Taunt all enemies within 8 yds" and Beckon 804914's "Taunt an enemy to attack you" as needing a
new C++ metric reading a creature's current combat target. Reading `CoAGameplayTest.cpp` found this metric
already exists (`victim`, `Unit::GetVictim() == target`, documented at `README.md:466-467`), so the
recommendation itself was stale, not the clauses: no new metric was needed, only a scenario that actually
puts a hostile creature in real combat with one actor so the taunt has a victim to redirect.

`coa-dbc-viewer record` confirms both clauses' real shape: 800424's effect 0 is `SPELL_AURA_MOD_TAUNT` with
`EffectImplicitTargetA[0]` 22 (`TARGET_SRC_CASTER`) + `EffectImplicitTargetB[0]` 15
(`TARGET_UNIT_SRC_AREA_ENEMY`) + `EffectRadiusIndex[0]` 14 (`SpellRadius.dbc` `RadiusMax` 8.0) — a
self-centred 8-yard taunt, matching the tooltip literally. 804914's effects are `SPELL_EFFECT_ATTACK_ME`
(`Spell::EffectTaunt`) and `SPELL_AURA_MOD_TAUNT` against `TARGET_UNIT_TARGET_ENEMY` — an explicit single
target. Both effects require the target's own threat list to be non-empty
(`Spell::EffectTaunt`/`AuraEffect::HandleModTaunt` both no-op on an empty list), so a real victim-switch
check needs a creature that is genuinely in combat with one actor before the gated spell is cast.

Every existing creature fixture in this harness (`creature_fixture`/`dummy_fixture`, `behaviours.py`) spawns
with `reaction: REACT_PASSIVE` by default. Reading `CreatureAI::UpdateVictim` (`CreatureAI.cpp`) found this
is why: a `REACT_PASSIVE` creature that already has a victim unconditionally gets `AttackStop()`'d on every
AI tick (`else if (me->GetVictim()) me->AttackStop();`), regardless of how the victim was set. This was
confirmed empirically, not assumed: a first attempt forcing a fixture's victim directly
(`Unit::Attack`/`CreatureAI::AttackStart`) showed the measured `victim` read `1` immediately and `0` within
the first AI tick afterwards in two independent gameplay runs; a second attempt using a real player `attack`
against the fixture showed the identical pattern. Every other scenario in this codebase only ever uses these
fixtures as damage/heal sponges, never as something that must sustain a real attack target, so this ceiling
was never hit before.

## Considered options

1. Add a new C++ action that force-sets the creature's combat/threat state directly (`ThreatMgr::AddThreat`
   + `CreatureAI::AttackStart`), bypassing the AI's own passive-reaction safety net. Rejected after testing:
   this still produces the same `AttackStop()` every tick, since the reaction state — not how combat started
   — is what `UpdateVictim` branches on; the extra C++ surface would exist for no benefit.
2. Give the aggro-redirect fixtures a non-passive `reaction` (`REACT_DEFENSIVE`) and prove the precondition
   with the existing `attack`/`stop_attack` actions (a real player melee swing), reusing the `creatures`
   JSON's own already-supported `reaction` field. Chosen: no new C++ action or metric at all;
   `REACT_DEFENSIVE` lets `CreatureAI::UpdateVictim`'s real `SelectVictim`-based branch run (so the dummy can
   actually hold and later lose a victim) while still not auto-aggroing anyone on sight the way
   `REACT_AGGRESSIVE` would, keeping the precondition deterministic (only the ally it is told to fight gets
   attacked, not whichever actor happens to be nearest when the scenario spawns it).
3. Fold the precondition into `target_count_scenario`'s existing dummy-ring pattern via a new `metric`
   option. Rejected: that scenario's whole shape (repeated casts, before/after-learn ratio) is for a
   hit-count clause, not a victim-switch one; it has no place for a prior real-attack setup phase per dummy.

Absolution's own radius needed one more empirical correction: a dummy placed 10 yd away (just past the
nominal 8.0 yd `SpellRadius.dbc` figure) still measured redirected. This reads as area-search hitbox padding
around the boundary (a known category in this engine, not investigated further here), not a defect in the
8-yard figure itself — proving that distinction precisely is a separate question from this capability's own
scope. The "outside the radius" target was moved to 20.0 yd, comfortably past any plausible padding, so the
clause itself ("within 8 yds" vs. clearly outside it) is still proven unambiguously.

## Decision

- `behaviours.py` gains `BEHAVIOUR_AGGRO_REDIRECT`, `AggroTarget`, `AggroRedirectSpec`,
  `aggro_redirect_scenario` and `aggro_redirect_spec`, and the `aggro_redirect` kind in
  `KINDS`/`BEHAVIOUR_CHECKS`/`behaviour_scenario`'s dispatch. An entry names the gated `spell`, a tuple of
  `targets` (`distance` from the caster, `expected_redirect`), and `self_cast` (true for a self-centred AOE
  with no explicit cast target, false for a single explicit target). Each target's own dummy fixture spawns
  `REACT_DEFENSIVE` (`AGGRO_REDIRECT_REACTION = 1`); the ally is relocated next to each dummy in turn (the
  fixtures are stationary, so this keeps the melee swing in range without moving the dummy itself off the
  distance its own radius clause is judged against) and attacks it for one swing interval, then stops; a
  `victim` reading before the gated cast asserts the real-combat precondition itself, and one after the cast
  per dummy proves whether that dummy's own victim switched to the caster.
- `compare.py` gains `behaviour_aggro_redirect_verdict`: an exact 0/1 comparison of the measured `victim`
  reading against `Expectation.displayed`, the same `exact()` shape every other cast-result-style judge in
  this file already uses.
- Two `classes/templar.json` entries close Beckon 804914's "Taunt an enemy to attack you" (one target) and
  Absolution 800424's "Taunt all enemies within 8 yds" (three targets: 3.0 and 6.0 yd inside the radius,
  20.0 yd clearly outside it).
- No server fix: both clauses are stock `Spell::EffectTaunt`/`SPELL_AURA_MOD_TAUNT` behaviour, unaudited by
  any existing scenario before this capability.

## Consequences

- `REACT_DEFENSIVE` dummy fixtures are now a reusable pattern for any future clause that needs a creature to
  genuinely hold and then lose (or keep) a real combat victim; `REACT_PASSIVE` stays the default for every
  other kind that only ever needs a damage/heal sponge.
- The 8-yard-boundary padding this step observed (redirected at 10 yd, not at 20 yd) is not characterised or
  fixed here; a future workstream that specifically needs the exact effective radius of an area-taunt-style
  effect should treat this ADR's finding as a starting point, not as proof of a defect.
