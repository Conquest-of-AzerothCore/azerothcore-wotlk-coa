# 0017. A hit ratio can read the hits of an owned creature entry

- Status: accepted
- Date: 2026-11-16

## Context

Dark Ranger 705465 and 707861 read: "Increases the Shadow damage dealt by your Shadow Hounds by $s2%." (Spell.dbc
server set, Description[enUS]; Effect[1] 190 with aura 79, misc 32, $s2 = 5 and 10). Their only label was the
data readback `effect_value e1 #0`. The hound's Shadow strike 706332 is cast by the owned creature (entry 50224 for
a Lesser Shadow Hound), not by the player, so `hit_ratio` (which reads the caster's own damage events) could not
read it. The harness already filters spell damage events by `caster_entry` (CoAGameplayTest.cpp, `casterEntry`).

## Options

- A new kind for hound hits: a shared tool addition beyond an opt-in field.
- `script_hit` with `caster_entry`: judges one hit against a formula, not a ratio between arms.
- An opt-in `caster_entry` field on `hit_ratio`, passed to the total and count reads.

## Decision

`caster_entry` (behaviours.py, `hit_ratio`): both reads of every trial carry `caster_entry`, so the totals and counts
are those of the caster's owned creature of that entry. Refused with swings, a rate entry, a metric other than
`spell_damage_total` or a reader other than the caster. Entries without the field generate unchanged.

## Consequences

- 705465 and 707861 carry a `hound_shadow` entry: Houndmaster's Call 802273 summons a Lesser Shadow Hound per trial
  with 705450 known in both arms; the control arm lacks the talent, the treatment arm learns it.
- Seeded tests in test_behaviours.py: the field reaches every read, an entry without it carries no filter, and swings
  are refused.
