# 0002. The Plaguefather emits Zombie Plague on every damaging hit

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Plaguefather 805048 reads "Damage dealt by this minion will emit Zombie Plague, dealing
${$504022m1+$504022ppl1+$SP*0.1} Plague damage to nearby enemies, and reducing their attack power by
${-($704706m1+$704706ppl1)}." No class code cast Zombie Plague 504022 on a Plaguefather 50385 hit: in 9000 ms of
combat only the Command's own cast landed (fix note FN-3). The live logs show the Plaguefather casting Zombie Plague
after 869 of its 1341 damaging swings (64.8%), with no internal cooldown, and no DBC field or tooltip states a chance
(805048 and 504022 ProcChance 101). The mentor approved the literal tooltip, every damaging hit (G-1); the live rate
is owner question Q-a1-9. Bone Toss 704706 is not tied to Zombie Plague in the logs and stays owner question Q-a1-8.

## Considered options

1. Leave the Plaguefather without the emission. Rejected: the tooltip states it and the logs show it.
2. Emit on 65% of hits. Rejected: no source states that chance.
3. Emit on every damaging hit. Chosen (mentor, G-1).

## Decision

- In aura_ascension_necromancer_event (AscensionNecromancerEvents.cpp), a damaging hit of a Plaguefather 50385 makes
  it cast Zombie Plague 504022 on itself (its own area around it), unless the hit is a Zombie Plague hit.
- The amount stays 504022's own value and coefficient row (0.1 spell power).

## Consequences

- One Zombie Plague per damaging Plaguefather hit; the Command still casts one of its own.
- Regression: the Plaguefather `zombie_plague` and `damaging_hits` entries (same arms, a control without a
  Plaguefather).
- If the owner rules a chance (Q-a1-9), the emission takes it as a roll.
