# 1002. Real-hit routes for a summon's crit damage, a summon's armor ignore and a spell deflect

- Status: proposed
- Date: 2026-11-17
- Builds on: ADR 0582, ADR 0997

## Context

Three Witch Hunter claims had no route (not-final part list 123.1, 362.2, 224.0): Deal With The Devil 680255 "Your and
your Shadow Hounds" (aura 163 given to the summons by Effect[2]), Decimate 804194 "and allowing them to ignore Armor"
(aura 280 rewritten to the Ascension ignore-armor aura, summons only) and Pavise 520865 (681453) "While you remain near
it, hostile spells targeting you are deflected" (aura 287 from the area aura 1108180 of the Pavise summon).

The first design read engine calculation functions with a probe amount (`SpellCriticalDamageBonus`,
`CalcArmorReducedDamage`, `GetTotalAuraModifier(SPELL_AURA_DEFLECT_SPELLS)`). Mentor D-462 ruled that such a read is
READBACK (data) on any unit, so it cannot prove a behaviour: the routes must use real hits as events. D-463 to D-468
approved the shapes below; a harness recorder of spell miss types (an `AllSpellScript::OnSpellHitResult` counter, the
hook already passes the final miss type, `Spell.cpp:3057-3060`) was not built (D-464) and stays a tool note for a
later class that needs miss types.

Facts the routes rest on: a hound deals Shadow damage through its own Houndmaster's Call strike 706332 (Effect[1]
SCHOOL_DAMAGE, SchoolMask 32, DmgClass melee, cast by the hound, `AscensionWitchHunterSummons.cpp:226-229`), whose
crit adds the hound's aura 163 (`Unit.cpp:1727-1757`); armor never reduces non-physical damage
(`Unit::IsDamageReducedByArmor`, `Unit.cpp:2400-2404`), so the armor claim is read on the pet's physical swings; the
engine deflects only from the victim's front 180 degrees (`Unit::MagicSpellHitResult`, `Unit.cpp:4087-4094`).

## Decision

- `hit_ratio` field `owned_auras` (`[[spell, stacks, entry]]`, opt-in): a precondition fixture set on the owned
  creature whose hits are read (`caster_entry`), with the harness `set_aura` by `owned_entry`, before every observed
  cast of both arms. 680255 `hound_crit` forces the Shadowhound pet's crits with it; the subject stays the crit damage.
- `metric_delta` option `deflect_arcs` (opt-in): a striker's landed spells at the caster in a control (no trigger), a
  front arm (judged: none land), an outside-radius arm (all land) and a behind arm (recorded, not judged; owner
  question on the arc, D-465). It holds the one READBACK row of `avoidance_samples`.
- Harness `avoidance_samples` probe id 7: the count of `SPELL_MISS_DEFLECT` results of the native
  `Unit::MagicSpellHitResult` over 512 samples (read only; the roll consumes random numbers), the data arm of the
  deflect type (681453 `pavise_deflect_rolls`).
- `metric_delta` option `pet_armor_arms` (opt-in): the current pet's plain swings, read by pet GUID (an entry match
  never selects a Pet), on an armored and a zero-armor dummy, without and with the trigger; judged ratio 1.0 with it,
  and as contrast the pet's read `armor_reduced_damage` per 1000 without it, both within 5% of the ratio. Its fixtures
  are removed and set again every window: `set_aura` on a held aura keeps the aura's running duration, which let the
  armor lapse in the first run (contrast 0.44 against the read 0.344).

Provisional number, renumbered at merge (guide 14.4).

## Consequences

- Seeded tests and mutants: `metric_delta_options/test_deflect_arcs.py`, `metric_delta_options/test_pet_armor_arms.py`
  and `HitRatioOwnedAurasTests` in `test_behaviours.py` (a 50% deflect, a Pavise deflecting outside its radius, a pet
  meeting the armor with the trigger, hounds without the crit damage aura all alert).
- Every addition is opt-in: entries that do not set the fields generate as before (Templar and Necromancer digests).
- New rows: `avoidance_samples` READBACK (`deflect_arcs`), `pet_melee_plain_damage` EVENT (`pet_armor_arms`); none in
  the closed base tables.
- Not covered: the 681453 behind arm (an owner question), and a crit of a Lesser Shadow Hound 50224, whose natural
  crits (about 0.3 per Call) stay under the hit ratio judge's half-of-trials floor without a fixture.
