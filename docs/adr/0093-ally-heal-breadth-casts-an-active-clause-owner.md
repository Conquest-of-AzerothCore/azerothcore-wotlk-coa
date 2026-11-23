# 0093. `ally_heal_breadth` casts an active clause owner after learning it

- Status: accepted
- Date: 2026-11-10
- Supersedes, for clause owners that are not passive: the "then learns `spell`" step of ADR 0080's Decision

## Context

ADR 0080 built the `ally_heal_breadth` check on the assumption that both of its clause owners were passives,
so learning the owner was enough to arm its heal. Chakra of Light 803159 is passive (`SPELL_ATTR0_PASSIVE` in
the server `Spell.dbc`). Libram of Grace 801463 is not: "Read from your Libram of Grace, increasing your healing
received by $s2% and causing your damaging abilities to restore ${$804150m1+$AP*.1+$SP*.15} health to you and
nearby allies for $d." It is a self-cast 20 s aura with a 180 s cooldown (effect 0 `SPELL_AURA_PROC_TRIGGER_SPELL`
on `TARGET_UNIT_CASTER`, trigger 804150 Grace). Its heal comes from `aura_ascension_templar_event`
(`AscensionTemplarEvents.cpp`, `case 801463: Cast(player, player, 804150)`), which runs only while that aura is
on the Templar.

Round 10 measured 0 of 2 allies healed before and after the learn. A diagnostic run of the same fixture
(`.cache/verify-all/20261110-115832`) read the Libram's aura 0 and 0 Grace heals after the learn alone. After a
self-cast of 801463 it read the aura 1, and each of the two allies and the caster was healed 3 times, once per
landed Argent Blade 807268.

## Decision

`ally_heal_breadth_scenario` reads the clause owner's `Attributes`. When the owner is not passive, it resets the
owner's cooldown, sets the power its cost needs and any `CasterAuraSpell`, then casts the owner on the caster and
waits its cast time plus `CAST_MARGIN_MS` between the learn and the after-phase trigger casts. A passive owner is
still only learned. The verdict (`behaviour_count`) and its labels are unchanged.

## Consequences

- The Libram of Grace scenario now measures the clause: 2 of 2 allies healed after the cast, 0 before.
- Round 10's `801463 behaviour_count` alert came from the fixture, not the server, and goes away when the
  scenario is regenerated.
- The breadth fixture still waits 500 ms between Argent Blade casts, which is less than the 1 s global
  cooldown, so every other cast fails with `SPELL_FAILED_NOT_READY`. That does not change whether an ally is
  healed, so it is left as it is.
- `apps/coa-gameplay-test/scenarios/templar-libram-of-grace-ally-heal-breadth.json` pins the server behaviour:
  no heal while the Libram is only learned, one Grace heal per Argent Blade on the Templar and on each grouped ally
  3 yd away, none on a grouped ally 25 yd away.
