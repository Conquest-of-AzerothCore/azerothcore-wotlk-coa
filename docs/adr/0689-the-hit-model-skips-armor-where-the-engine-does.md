# 0689. The hit model skips armor where the engine does

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0688

## Context

Stake 681350 says "${$m1+0+$AP*.675} Physical damage, ignoring enemy armor." The server gives every Stake rank
(680537, 681347-681352) `spell_custom_attr` 32768, `SPELL_ATTR0_CU_IGNORE_ARMOR`
(`rev_20260907_18_witch_hunter_stake.sql`, also in the world baseline). The counted pair of ADR 0688 read a
`hit_mean` of 834.2 / 830.4 over 333 usable hits against the tooltip's 829.85, while the hit model expected 757.3:
`mitigation.expected_mitigation` applied the reference armor (528) to every school mask with the physical bit and
read no spell attribute. Mentor D-87 (approved under O-12) asks the model to mirror the engine's own test.

The engine's test, as this tree builds it:

- `Unit::IsDamageReducedByArmor(schoolMask, spellInfo, effIndex)` (Unit.cpp:2422-2442): no armor without the
  physical bit; none with `SPELL_ATTR0_CU_IGNORE_ARMOR` (Unit.cpp:2430); none for a bleed (spell or effect mechanic
  15, `SpellInfo::GetEffectMechanicMask`, SpellInfo.cpp:2234-2242) when an effect index is passed and that effect is
  `SPELL_AURA_PERIODIC_DAMAGE` or `SPELL_EFFECT_SCHOOL_DAMAGE` (Unit.cpp:2434-2438).
- Direct damage, `Unit::CalculateSpellDamageTaken` (Unit.cpp:1704): armor only without
  `SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS` (0x100) and with no effect index, so the bleed exception does not apply.
- Periodic damage ticks (SpellAuraEffects.cpp:6655) pass the effect index and do not check the attribute 4 bit.
- `AttributesCu` gets the table's bits by OR (`SpellMgr::LoadSpellInfoCustomAttributes`, SpellMgr.cpp:3633-3707).

## Options

- A class-file list of spells that ignore armor: an authored copy of server data, out of step on the next change.
- Read the attribute live with the harness's `spell_uses_armor` metric (CoAGameplayTest.cpp:5182-5189): a run is
  needed before a model exists, and the generated expectation would change shape.
- Mirror the test offline from the data the engine reads: Spell.dbc fields and the `spell_custom_attr` rows of the
  world SQL tree.

## Decision

- `mitigation.reduced_by_armor(school, ArmorFacts)` mirrors the rules above; `expected_mitigation` takes an optional
  `spell: ArmorFacts` and keeps no armor reduction (mean 1, no variance) when the rule says so. Without facts the
  previous behaviour holds (melee swings, Unit.cpp:1973).
- `custom_attr.custom_attributes()` reads `spell_custom_attr` as `bonus_data` reads `spell_bonus_data`: the world
  baseline or base dump, then the update files the updater would still apply, in its order. It replays DELETE,
  INSERT and the keyed `attributes |`, `& ~` and plain assignments; any other statement, or a module world file
  naming the table, makes it unreadable. `bonus_data` now exposes `world_of`, `update_directories`,
  `pending_updates` and `shown_directories` for both readers, with the same output.
- `hits.spell_mitigation` builds the facts of the hit spell (the triggered spell for a periodic weapon trigger) for
  physical school masks: the table's bits, Spell.dbc `AttributesEx4`, `Mechanic`, `EffectMechanic`, `Effect` and
  `EffectApplyAuraName`; `periodic` for a periodic damage aura. Rank hits and script hits use it. An unreadable table
  leaves a physical hit unmodelled.
- Not modelled: `AttributesCu` or attribute bits set in C++ at load (for example
  AscensionWitchHunterCompletion.cpp:374-381) and attributes a spell twin copies (SpellMgr.cpp:3710-3715). Those hits
  keep the previous model.

## Consequences

- Witch Hunter: the generated Stake 681350 `hit_mean` reference moves from 757.3 (sigma 43.7) to 829.5 (sigma 47.9);
  no other class 15 scenario or expectation changes. The class's ranks and script hits whose eligibility changes are
  the seven Stake ranks only.
- Finished classes: no Templar (19) or Necromancer (23) class spell, rank, triggered spell of a rank or spell named in
  their class files that is a rank or script hit changes eligibility; their generated scenarios are byte-identical
  (the snapshot check of the source stage covers them).
- No step sets a dummy's armor; the Stake `hit_mean` runs on the reference dummy, whose armor (528) the scenario
  reads, so the same read separates the unmitigated 829.5 from the armored 757.3.
- Tests: `test_mitigation.ArmorEligibilityTest` (plain physical, the custom bit on both paths, the attribute 4 bit on
  the direct path only, a bleed tick against a direct bleed hit, magic); `test_custom_attr` (replay, bit updates, an
  unreadable statement, every Stake rank in the repository world); `test_hits.IgnoredArmorTest` (the seeded
  834.2 / 830.4 over 333 hits are ok; mutant: the same reads alert without the custom attribute; an unreadable table
  leaves the hit unmodelled).
