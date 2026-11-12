# 0081. `cast_condition` behaviour kind for caster-state castability clauses, and a Templar mounted-only fix

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's `cast-conditions-cooldowns` workstream carries several Templar tooltip clauses that gate
castability on the *caster*'s own transient state rather than the target's health: Divine Charge 527023's
"Can only be used outdoors." and Crusader's Presence 562302's "Can only be used while Mounted." The existing
`cast_gate` kind (ADR 0046) is specific to `TargetAuraState`/bypass-spell triples and does not fit: neither
clause has a target-health gate or a bypass spell, and each needs a different setup (a location, a mount
state).

Reading `Spell.cpp` confirms 527023's clause is the stock engine path: `SPELL_ATTR0_ONLY_OUTDOORS` (527023's
own `Attributes` DBC field) returns `SPELL_FAILED_ONLY_OUTDOORS` (93) from `!caster->IsOutdoors()`
(`Spell.cpp:5857-5859`). 562302's clause is not: its `Attributes` carries only
`SPELL_ATTR0_ALLOW_WHILE_MOUNTED`, which *permits* casting while mounted (bypassing the generic
dismount-exempt check at `Spell.cpp:6189-6197`) but does not *require* it, and its `CasterAuraState`/
`CasterAuraSpell` DBC fields are both 0. No Templar script (`AscensionTemplarAbilities.cpp`,
`AscensionTemplarAuras.cpp`) touches 562302 either. A gameplay run of the unfixed cast (see Verification)
reproduced the cast succeeding while unmounted — a confirmed defect, not an audit mislabel.

## Considered options

1. Extend `cast_gate` to accept a caster-state condition in place of its `TargetAuraState`/bypass-spell
   shape. Rejected: `cast_gate`'s three-attempt ordering and its creature-fixture target health machinery
   have no caster-state analogue, and squeezing two unrelated condition shapes behind one spec would make
   neither reading obvious.
2. Add a separate kind per condition (`cast_outdoors`, `cast_mounted`). Rejected: both are the same shape
   (one gated spell, one caster-state setup pair, one blocked/allowed pair of attempts reading the existing
   `cast_failure` metric) with only the setup steps and the expected refusal code differing; a single kind
   parameterised by `condition` avoids duplicating the attempt/judging machinery for what is otherwise one
   capability.
3. Add a new `cast_condition` behaviour kind: one gated spell, a `condition` (`"outdoors"` or `"mounted"`)
   selecting its setup pair, and a `blocked_result`. Chosen: reuses `cast_gate_power_step`/`cast_gate_label`'s
   shape for the attempt itself (`reset_cooldown`, power fixture, cast, wait, `cast_failure` measurement) and
   the existing `behaviour_cast_gate_verdict` judge unchanged, so no new verdict function or harness metric
   is needed; only the setup differs per condition.

For the location pair needed by `"outdoors"`, reusing the indoor/outdoor coordinates already proven by
`scenarios/reaper-ghost-form-indoor-corpse-reclaim-6437.json` (map 0, Firebrew Inn indoor at
`(-4840.67, -857.094, 501.997)`, open-world outdoor at `(-9617.06, -288.949, 57.3053)`) was chosen over
picking new coordinates, since that scenario already demonstrates both points' indoor/outdoor status through
a passing assertion, rather than this entry asserting it fresh on unverified coordinates. For `"mounted"`,
applying a generic ground-mount fixture aura (458, Brown Horse, confirmed `SPELL_AURA_MOUNTED` in
`Spell.dbc` effect 0) directly through the existing `set_aura` action was chosen over casting an actual mount
spell, since it needs no class-specific mount ability and no additional cast step, and `set_aura` already
runs the real `AddAura` aura-application pipeline (so `Unit::IsMounted()`'s `UNIT_FLAG_MOUNT` is set the same
way a real mount cast would set it).

## Decision

- `behaviours.py` gains `BEHAVIOUR_CAST_CONDITION`, `CastConditionSpec`, `cast_condition_scenario` and
  `cast_condition_spec`, and the `cast_condition` kind in `KINDS`/`behaviour_scenario`'s dispatch. A
  `cast_condition` entry names the gated `spell`/`name`/`quote`, a `condition` (`"outdoors"` or `"mounted"`)
  and the `blocked_result` `SpellCastResult` code.
- `compare.py` reuses `behaviour_cast_gate_verdict` unchanged for `BEHAVIOUR_CAST_CONDITION`: the same exact
  `cast_failure`-vs-reason-code comparison applies regardless of which kind produced the expectation.
- Two `classes/templar.json` entries close Divine Charge 527023's outdoors-only clause and Crusader's
  Presence 562302's mounted-only clause.
- **Server fix**: `AscensionTemplarAbilities.cpp`'s Templar-scoped `templar_casts` `AllSpellScript` gains an
  `OnSpellCheckCast` hook (and the matching `ALLSPELLHOOK_ON_SPELL_CHECK_CAST` registration) that returns
  `SPELL_FAILED_ONLY_MOUNTED` for spell 562302 when `!player->IsMounted()`, scoped to `SpellFamilyName == 25`
  (Templar) so no other class's cast check is touched. This is the same per-class `AllSpellScript` +
  `SPELL_FAILED_ONLY_MOUNTED` idiom `AscensionTinkerAbilities.cpp`'s `tinker_spells::OnSpellCheckCast`
  already uses for an analogous Tinker-only mounted-form gate (`AscensionTinkerAbilities.cpp:88`); it is not
  shared code, each class keeps its own copy per the round's "never link one class's effects to another's"
  rule.

## Consequences

- A future caster-state castability clause (in-combat, a party-aura requirement, etc.) on any class can
  either extend `CastConditionSpec.condition` with a new setup pair if its shape matches (one gated spell,
  one setup/teardown pair, one blocked/allowed attempt), or needs its own kind if it does not — Spiritual
  Ascension 500688's "Usable while in combat." needs a dead-ally resurrection target, which this shape does
  not cover, and is left for a later step.
- 562302's fix only gates the cast attempt; no change was needed to 562302's own aura effects (still
  `SPELL_AURA_MOD_MOUNTED_SPEED_NOT_STACK` etc.), since those already do nothing useful while unmounted — the
  tooltip's restriction was purely a missing cast-time check, not a missing effect.
