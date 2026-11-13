# 0083. `mount_grant` behaviour kind for multi-actor mount grant and cast-persistence clauses

- Status: accepted
- Date: 2026-11-10

## Context

Round 10's `cast-conditions-cooldowns` workstream still carries two of Divine Charge 527023's clauses:
"You and your party members leap upon a divine steed," (a mount grant to the caster *and* every nearby party
member, not just the caster) and "While active, casting does not dismount you or your allies." (the caster
can keep casting afterwards without losing the mount, and so can the allies it already mounted). Neither
existing kind fits: `cast_condition`/`cast_gate` only ever measure a single actor's own `cast_failure`, and
no existing kind measures a state on a second player actor at all.

Reading the DBC and source confirms the mechanism. 527023's own effect 0 (`EffectImplicitTargetA[0]` 34,
`TARGET_UNIT_DEST_AREA_PARTY`, `SpellInfo.cpp` target-info table index 20; `EffectRadiusIndex[0]` 9 ->
`SpellRadius.dbc` `RadiusMax` 20.0 yd) is a self-centred party-area aura. `AscensionTemplarAuras.cpp`'s
`aura_ascension_templar_lifecycle::Apply` (`id == 527023`, gated on `First(effect)`) casts the target's own
527272/527270 the first time this aura applies to a live, unmounted player target; 527272's own `Apply`
calls `GetTarget()->Mount(14584)` directly, so `Unit::GetMountID()` (the existing `mount_display_id` metric,
`CoAGameplayTest.cpp`) reads 14584 on every target the party-area aura reaches, caster and ally alike. The
persistence clause is a stock-engine bypass named for this exact spell: `Spell.cpp:6189-6197`'s own comment
("Divine Charge explicitly permits its recipients to cast on the finite steed") reads
`bool divineSteed = m_caster->IsOnDivineSteed()` and exempts any non-passive cast from the generic
`IsMounted()`-forces-`SPELL_FAILED_NOT_MOUNTED` gate when true. `Unit::IsOnDivineSteed()` (`Unit.cpp`
~18925) checks `GetAura(527272)`'s own caster is a class-19 player (`CLASS_MONK` is this engine's enum name
for the class whose in-game title is Templar, `SharedDefines.h:145`, confirmed by reading the enum
definition directly rather than assumed from the identifier) and `GetMountID() == 14584` — on the *target*
being checked, not the caster of the spell about to be cast, so this holds for an ally mounted by 527023 just
as much as for the Templar caster, independently of the ally's own class. Both clauses are already correct
stock-engine/CoA-script behaviour, unaudited by any existing scenario.

## Considered options

1. Extend `cast_condition`/`cast_gate` to accept a second measured actor. Rejected: both kinds' whole shape
   (a single gated spell, a single `cast_failure` attempt/judge pair) has no second-actor concept anywhere,
   and the clauses here measure a state (`mount_display_id`), not a cast result.
2. Two separate kinds, one per clause (a `mount_grant` presence check and a separate `mount_persist` check).
   Rejected: both clauses measure the exact same metric (`mount_display_id` on the caster and an ally) and
   differ only in when the measurement is taken (right after the grant cast, or after a further unrelated
   cast); one kind producing two `Expectation`s from one scenario avoids casting 527023 and grouping the
   ally twice.
3. A new `mount_grant` kind: one scenario groups the caster with an `ALLY` player actor (`values.ALLY`,
   already used by `hits.py` for ally-targeted heals), casts the granting `spell` once, reads
   `mount_display_id` on both actors (`granted`), then casts an unrelated `persist_spell` on the caster and
   reads `mount_display_id` on both actors again (`persisted`). Chosen: one scenario proves both clauses
   together, reuses the existing `group`/`mount_display_id` harness primitives and the `ALLY` actor
   convention with no new metric or action.

For the "unrelated cast" that proves persistence, the already-proven-in-this-round Crusader's Presence
562302 (itself gated on `IsMounted()` by ADR 0051's fix) was chosen over inventing a new spell dependency,
since it needs no new facts and is textually a genuine "casting" the tooltip's clause covers.

## Decision

- `behaviours.py` gains `BEHAVIOUR_MOUNT_GRANT`, `MountGrantSpec`, `mount_grant_label`,
  `mount_grant_scenario` and `mount_grant_spec`, and the `mount_grant` kind in `KINDS`/
  `BEHAVIOUR_CHECKS`/`behaviour_scenario`'s dispatch. A `mount_grant` entry names the granting `spell`,
  `grant_quote`/`persist_quote` (the two tooltip clauses), `mount_display_id` (the expected
  `Unit::GetMountID()` value) and `persist_spell` (the unrelated spell cast to prove the second clause).
- `compare.py` gains `behaviour_mount_grant_verdict`: reads both of a moment's `caster_label`/`ally_label`
  measurements and compares each to the entry's `expected` display id for exact equality
  (`FLOAT_EPSILON`), `ok` only when both actors match.
- One `classes/templar.json` entry (`variant: "mount_grant"`, to disambiguate the manifest key from
  527023's own `cast_condition` entry) closes both of Divine Charge's remaining clauses.

## Consequences

- A future multi-actor state-presence clause (a shared buff grant, an aura that must reach every party
  member) can reuse this same `caster_label`/`ally_label` model-pair shape in its own `Expectation.model`
  rather than inventing a new per-actor convention each time.
- This kind only measures `mount_display_id`; a clause needing a different per-actor metric (health,
  another aura) would still need its own kind or a parameterised metric field, left for when such a clause
  is actually encountered.
