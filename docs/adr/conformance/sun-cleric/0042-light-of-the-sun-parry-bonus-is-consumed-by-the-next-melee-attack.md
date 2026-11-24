# 0042. Light of the Sun's parry bonus is consumed by the next melee attack taken

- Status: accepted (owner ruling O-31, 2026-11-23)
- Date: 2026-11-23

## Context

Light of the Sun 704941: "Parrying an attack now restores $707843s2% of your maximum health and increases your chance
to parry the next attack by $707843s1%." Its buff 707843: "The chance to parry the next attack is increased by
${$w1}%." (server DBC set). 707843 has Effect[0] aura 47 MOD_PARRY_PERCENT 30, Effect[1] HEAL_PCT, DurationIndex
28 = 5000 ms, ProcCharges 0, ProcFlags 0 and AuraInterruptFlags 0: nothing in the data ends it before 5 s.

The class check (`AscensionSunClericEvents.cpp`, case 704941, from e36bc50aad) accepted parries only, and the proc
cast 707843. The entry `704941 behaviour_metric_delta parry_next` read 30 after a landed Night Slaughter 23583
(melee damage class), where "the next attack" reads 0: pair 20261122-220055 / 20261122-220128 (owner packet,
row 264), and pair 20261123-074609 / 20261123-074902 on this branch's pre-fix build.

The owner ruled (O-31): the bonus is consumed by the next melee attack taken against the caster, parried or not; a
spell does not consume it.

## Options

1. In the class code, accept every melee attack taken in the 704941 case and remove 707843 there, casting it again
   when that attack is parried.
2. A spell_proc row for 707843 with one charge on melee attacks taken. Rejected: the class code already receives
   every taken event through the 704941 row (ProcFlags 1048575, HitMask 32767), and a charge-consumed aura removed
   in the same event that casts it again depends on the engine's order of proc handling.
3. Keep the 5 s aura and reword the tooltip. Rejected by the ruling.

## Decision

Option 1. The 704941 check accepts a non-periodic melee attack (an auto attack or a melee damage class spell) taken
from another unit. Its proc removes 707843 from the caster, then casts it again when the attack was parried: the
parry roll of that attack has already read the bonus, and a parry grants a new one, as the tooltip says. Any other
damage class does not reach the case and leaves the aura.

## Consequences

- One melee attack taken after a parry ends the bonus, landed, dodged, missed or parried (a parried one grants a new
  bonus); a spell leaves it; with no attack it lasts its 5000 ms.
- Readers: 707843 is named only by this case (no other C++, no SQL row). 704941 is read by the class event list
  (`AscensionSunClericData.h`), its spell_proc and spell_script_names rows (`rev_20260909_13`) and the class 27 tree
  of mod-spellbook. No other class, no shared engine path.
- Regression: `parry_next` (a landed Night Slaughter consumes it, now ok), `parry_spell` (Grave Coil 47632, magic,
  leaves 30), `parry_held` and `parry_gone` (30 just before 5 s, 0 just after, apply-stamp bracketed); the control is
  each entry's phase without 704941. A parried next attack is not built: `second_strike` sets the caster's parry
  to 0.
- After the change, pair 20261123-075028 / 20261123-075125 (worldserver 8b815e5448674b97): parry_next reads 0
  (30 before the second strike, one landed in each phase), parry_spell 30, parry_held 30 at 4536..4860 ms after the
  apply, parry_gone 0 at 5036..5360 ms; heal, parry and parry_chance unchanged (ok). Before: worldserver
  40dbb7b6c03e7dd3, parry_next alert 30, the other three ok.
- Client text unchanged.
