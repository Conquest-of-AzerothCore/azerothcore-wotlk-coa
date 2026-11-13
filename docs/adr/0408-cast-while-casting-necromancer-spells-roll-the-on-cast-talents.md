# 0408. Cast-while-casting Necromancer spells roll the on-cast talents

- Status: accepted
- Date: 2026-11-13

## Context

Permafrost 704681 states "Gives your spells a $h% chance to grant you the Permafrost". Sixty Grave March 500991
casts rolled no Permafrost (pairs 20261113-014415 / -014447 and 20261113-021019 / -021054), while Command: Undead
rolls it at 14.4%. Grave March carries SPELL_ATTR4_ALLOW_CAST_WHILE_CASTING; the Spell constructor adds
TRIGGERED_IGNORE_CAST_IN_PROGRESS | TRIGGERED_CAST_DIRECTLY to such casts (Spell.cpp:641-642), so Spell::IsTriggered()
is true for a player's own Grave March, and necromancer_casts::OnSpellCast returned on IsTriggered() before every
on-cast roll.

Spells of family 29 or of the class-23 ledger with the attribute (server DBC set): in the ledger Undead: Assault
500982, Undead: Pacify 500983, Undead: Protect 500985, Grave March 500991, Army of the Dead 525600; outside the ledger
500095, 500327, 504692, 504902, 525388, 525389, 570127, 572778, 572781, 706967, 800755, 801527, 801545, 801940, 802082,
802084, 802106, 802751, 804528, 805613, 805681, 806387, 806389, 808032, 808033, 808034, 808035.

The on-cast rolls behind the early return, with their tooltip words:
- Permafrost 704681: "Gives your spells a $h% chance to grant you the Permafrost".
- Tundra Warriors 92122: "Casting any spell now has a $h% chance to grant you Tundra Warriors."
- Diabolical 704723: "Casting spells now grants you 1 stack of Diabolical".
The rest of OnSpellCast (buff charge consumption, the Command block, Mindless Fury's army buff, the 805029 and
801938 hooks) is tied to named spells or to Commands and summons, not to "your spells".

## Decision

- Mentor ruling of 2026-11-13 (FN-a4-1, approved in principle): when OnSpellCast decides whether a cast is
  triggered, it ignores only the two flags the attribute adds. A spell with the attribute and no other trigger flag is
  the player's own cast; IsTriggered() and Spell.cpp are unchanged.
- Such a cast runs only the three rolls whose tooltip covers every spell cast: Permafrost, Tundra Warriors and
  Diabolical. Everything else in OnSpellCast keeps skipping it.

## Consequences

- Grave March and the Undead stances roll Permafrost and Tundra Warriors and grant Diabolical stacks.
- Regression entries `704681 behaviour_metric_delta grave_march` (0 -> 2 charges), `92122 behaviour_metric_delta
  grave_march` (707421 present after 60 Grave Marches) and `704723 behaviour_metric_delta grave_march` (3 stacks after
  3 Grave Marches), each with its no-cast control. `704723 behaviour_metric_delta triggered` is the triggered-cast
  control: Vampiric Aura 300241, set on the caster by harness set_aura as a precondition fixture, triggers 560607
  (family 29) every second as a real triggered cast, which still grants no stack; `triggered_ticks` shows those casts
  happened (560607 on the caster).
- No tool code changed, so no seeded tool test applies. Mutant (design, not run): dropping the IsTriggered() term of
  the early return would let the 560607 ticks grant stacks, so the `triggered` entry must alert.
