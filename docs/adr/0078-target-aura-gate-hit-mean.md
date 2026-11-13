# 0078. A `target_aura_gates` recast-on-target gated `hit_mean` check

- Status: accepted
- Date: 2026-11-10

## Context

Templar's Might (705291) states "Damage dealt by Righteous Lunge, Chastise, Blade of Faith, and Scourgebane on
enemies affected by your Condemn is now increased by `$s1%` per stack." The existing `705291 e0 spell_modifier
567539`/`705291 e0 spell_effect_value 567539` checks only confirm the +6 flat `SPELLMOD_EFFECT2` token value on
Condemn's own `CalcValue`; neither reads whether the bonus actually changes a named spell's *realized* damage, nor
whether it is absent against a target that does not carry the caster's Condemn debuff. `SPELLMOD_EFFECT2`
modifies Condemn's effect index 1 (`Unit::ApplyEffectModifiers`, `SpellAuraEffects.cpp`/`Unit.cpp`), a native
`SPELL_AURA_MOD_DAMAGE_FROM_CASTER` (271) effect consumed by `Unit::SpellDamageBonusTaken`/`MeleeDamageBonusTaken`
(`Unit.cpp:10049`/`:11639`) on whichever unit carries the aura — the gating and the magnitude are both read from
a live aura on the *target*, not from the caster's own spellmods, so no existing `metric_delta`/`passive_delta`
check (all caster-side) can observe either half of the clause.

## Considered options

1. Extend `metric_delta` to read a target-side field once before/after a single trigger cast. Rejected: the
   clause's quantity is a realized *damage* change, which has weapon/roll variance requiring many trials to
   clear the standing 5% tolerance (confirmed empirically: the existing `503141 hit_mean` baseline already needs
   hundreds of hits for this exact tolerance at this spell's variance) — a single-cast delta cannot resolve it.
2. Add a `target_aura_gate` opt-in parameter to `hit_parts`: recast the gate spell (Condemn) on the dummy target
   before every measured cast of the named rank, across the same many-trial, many-part infrastructure the
   existing `hit_mean` check already uses, and scale the expected mean by the known modifier. Chosen.

## Decision

- `hits.py`: `hit_parts` gains an optional `gate: tuple[gate_spell, percent, enabling_spell] | None` parameter.
  When given, it: validates the model is hostile; learns `enabling_spell` (the passive that owns the spellmod,
  so it is not confused with a scenario-wide class-file override); adds `gate_fixture_steps` (reset the gate
  spell's cooldown, restore its own power cost, cast it at the dummy target, wait out the GCD, then restore the
  rank's own power cost) to the existing per-cast `cast_fixtures` list, so it runs before every trial exactly like
  the existing ally-relocate fixture; and scales the expected mean by `1 + percent/100`. Timing: the trailing
  per-cast wait keeps its original value (so the scenario does not waste simulated time), while a separate
  `budget_interval` (which does include the gate's own wait and per-step tick overhead, `GATE_FIXTURE_STEP_COUNT *
  READ_STEP_MS`) drives `part_casts`/`timed()` sizing — conflating the two caused two iterations of false "timed
  out during setup" gameplay failures before this split was found.
- `measured_hit_model` (also in `hits.py`) reads a new `gate_multiplier` field straight from the Expectation's
  own `model` dict (set once, at scenario-build time, exactly like the existing `part_casts`-driven
  `self_stack_multiplier` lookup) rather than re-deriving it from the class file, so the judge reproduces exactly
  the scaling the scenario was built with.
- `conformance.py`: a new `target_aura_gates` class-file list (parallel to `behaviours`, but dispatched through
  the same multi-part writer `add_hit` already uses, since `behaviour_scenario`'s one-scenario-per-entry contract
  cannot hold the several hundred trials this check's tolerance needs) and `add_target_gate`/`target_gate_entries`
  plus a `--target-gate` CLI flag.
- `scaffold.py`'s `EMPTY_LIST_FIELDS` gets the new key.
- `classes/templar.json` gets one `target_aura_gates` entry for 705291 (`rank: 503141` (Chastise), `gate_spell:
  567539` (Condemn), `percent: 18.0` — Condemn's `StackAmount` of 3 re-cast on the target every trial ratchets to
  and holds at the cap per `Aura::ModStackAmount`'s clamp, and `AuraEffect::CalculateAmount`'s `amount *=
  GetBase()->GetStackAmount()` multiplies the stored +6 by the live stack count, confirmed directly via an
  `aura_amount` probe showing +6 after a single cast).

## Consequences

- Any future target-debuff-gated damage clause (this class's or another's) gets the same proof with a four-field
  class-file entry and no new tool code.
- This check ran clean (no crash, no timeout, two independent native passes) and judged **`alert`**: two
  independent gameplay samples (45 and 587 hits) both measured a mean statistically indistinguishable from the
  *unscaled* baseline (349.2/587-hit 349.24 vs 348.14 expected-without-gate, far from both +6% and +18%), while a
  direct `aura_amount` probe on the dummy confirms the aura's own stored amount on effect index 1 is +6 after a
  single cast. The spellmod, the aura, and the classmask match (verified: Chastise's `SpellFamilyFlags[1] =
  67108865` overlaps Condemn's effect-1 `EffectSpellClassMask` bit `67108864`) all read correctly from DBC and
  source; `AscensionInheritsResolvedAmount`, `SpellInfoCorrections.cpp` and the Templar-specific Oath-clearing
  hooks (`AscensionTemplarAbilities.cpp`'s `Breaker`/`ClearOaths` branch, which Chastise's own
  `SpellFamilyFlags[2] = 128` triggers on the caster, not the target) were checked and ruled out as the cause.
  No further, conclusive root cause was found this step. Per AGENTS.md's "never guess a cause" rule, no fix is
  proposed without one: this clause is **not** added to the ledger and is **not** closed. It is the first
  concrete, reproduced evidence that this specific defect exists, and is handed to the next step as the priority
  item (continuing this same investigation, not a new capability) rather than a newly invented one.
