# 0013. Fel Torpedo hits each enemy once per caster per cast

- Status: accepted (owner ruling Felsworn O-25 (2026-11-23, Felsworn ADR 0013))
- Date: 2026-11-23

## Context

Fel Torpedo 500610: "Torpedo forward in the direction you're running and deal
${$500761m1+$500761ppl1+$AP*.35} Shadowflame Damage to enemies in your path." The text gives one amount and no hit
count.

Server DBC set: 500610 Effect[2] is aura 23 `SPELL_AURA_PERIODIC_TRIGGER_SPELL`, amplitude 250 ms, duration 500 ms,
`SPELL_ATTR5_EXTRA_INITIAL_PERIOD`, trigger 500761: up to three ticks, each casting 500761 at every enemy within 3 yd
of the caster while Effect[1] (802028) dashes it 10 yd ahead. 500761 has no target exclusion; its Effect[2] puts the
hidden 1000 ms "Debuff Dummy" 500762 on each enemy hit, and nothing on the server reads it.

Measured on the pre-fix server (fw-t4 runs 20261123-185607 and 20261123-185756; tick probe runs 20261123-193633,
-193731, -193703 and -193807): two 500761 hits per cast on one dummy in every trial, at 2 yd (ticks 1 and 2) and at
9 yd (ticks 2 and 3), so 610 per cast at attack power 312 against the 305 of one hit.

Live evidence: none. coa-history holds 6 casts of 500610 in one log and no event of 500761 in 186 logs, so the hit
count per cast cannot be read from live play. The basis is the owner's ruling alone.

Ruling Felsworn O-25 (2026-11-23): each enemy is damaged once per caster per cast; two Felsworns on the same enemy each land their own hit.

## Options

- `ExcludeTargetAuraSpell = 500762` on 500761 in the class contracts. Rejected: `SpellInfo::CheckTarget`
  (SpellInfo.cpp:2180) calls `Unit::HasAura` without a caster GUID (Unit.h:1518), so one Felsworn's marker would block
  every other Felsworn's Torpedo on that enemy for a second.
- A `SpellScript` target filter on 500761 that reads 500762 from this caster. Needs a `spell_script_names` row, and the
  1000 ms marker outlives the 500 ms cast, so it ties the rule to a timer rather than to the cast.
- The class's existing `OnSpellBeforeEffects` hook: the class state keeps the enemies hit by this caster's current
  500610 cast, cleared at each 500610 cast; a 500761 cast drops those enemies from its target list before launch and
  records the enemies it hits.

## Decision

The third option, in `AscensionFelswornAbilities.cpp` (`Torpedo`, called from `felsworn_casts::OnSpellBeforeEffects`),
with the list in `FelswornState::torpedoed`. The list belongs to the casting player and is cleared by that player's
500610 cast, so the rule is per caster and per cast. Only enemies whose hit landed (`SPELL_MISS_NONE`) are recorded, so
an enemy missed by one tick can still be hit by a later tick of the same cast. A dropped enemy is removed before
`HandleLaunchPhase` and `SendSpellGo`: it takes no damage, no threat and no 500762, and appears in no hit or miss list.

## Consequences

- One 500610 cast deals one 500761 hit to each enemy it reaches (305 at attack power 312 at level 60), whatever the
  tick on which it reaches it. A second Felsworn's cast on the same enemy lands its own hit.
- Keyed to 500610 and 500761 by id, for a player of the class (`Owner`). 500761 is triggered only by 500610 (full
  Spell.dbc scan) and no other class file or source names either spell. No engine, SQL, DBC or client text change.
  500762 stays as the data has it and is still read by nothing.
- Regressions: `caster_hits` entries `torpedo_once` (one caster, dummy 2 yd ahead), `torpedo_once_far` (9 yd ahead)
  and `torpedo_two_casters` (two casters at one spot, the second 100 ms after the first), each reading every caster's
  own 500761 hits before and after every cast: exactly one more per caster per cast. The damage per hit stays on
  `torpedo_hit` and `torpedo_hit_ap` (ADR 0009).
