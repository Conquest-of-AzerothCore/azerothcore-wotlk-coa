# 0013. Plague Horde is cast by the minion on itself

- Status: accepted
- Date: 2026-11-13

## Context

Plague Horde 802986: "Damage dealt by your Undead minions now has a $h% chance to cast Plague Horde on themselves for
$807653d ... Enrage for $d, increasing their critical strike chance by $807765s1%." On a minion's damage,
AscensionNecromancerEvents.cpp cast Plague Horde 807653 with the player as caster and the minion as target; every
807653 effect (auras 79, 192, 216) is TARGET_UNIT_CASTER, so the aura landed on the player, and the crit aura 807765
was cast nowhere. With the forced roll of ADR 0482 the Enrage read 1 on the caster and 0 on the Ghoul (pair p6,
20261113-063750 / -063818). The live logs show 6089 applications of 807653, all self-cast by a minion, each with 807765
on the same minion within 0.2 s. Fix note F-ma-1 was approved by the mentor (G-37) on 2026-11-13.

## Decision

- Plague Horde only: in that branch the minion casts 807653 and 807765 on itself. The Zombie Plague cast
  (Cast(actor, actor, 504022)) is unchanged.

## Consequences

- Regression (class file, forced roll of ADR 0482, no-talent before phase as control): both Ghouls carry one 807653 and
  one 807765; neither is on the caster; the Ghoul's crit chance rises by 10 points; 807765's applied duration is its
  DBC 5000 ms (ADR 0484).
- The 10% rate stays proven by 802986 proc_rate (ADR 0346).
