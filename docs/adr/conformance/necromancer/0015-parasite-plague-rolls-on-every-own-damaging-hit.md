# 0015. Parasite Plague rolls on every own damaging hit

- Status: accepted
- Date: 2026-11-13

## Context

Parasite Plague 560730: "Damage dealt now has a $h% chance to apply Parasites for $560729d." ($h = ProcChance 5).
`aura_ascension_necromancer_event::Proc` rolled `Chance(player, 561319) || Chance(player, 560730)` inside its
periodic branch (AscensionNecromancerEvents.cpp:117-125), so direct hits never applied Parasites: the counted pair
20261113-073520 / -073802 read 0 in 4730 direct Glacial Impact 707592 hits against 4.90% / 5.31% on periodic Blight
hits. The mentor approved fix note FN-mb-2 / FN-mc-3 (2026-11-13) on the condition that live direct hits apply
Parasites: side c's raw-log scan counts 107 of 119 player-applied Parasites after a SPELL_DAMAGE of the same player on
the same target (side b's scan of the same logs: most of those SPELL_DAMAGE events are Blight 500237 and Rot
Fetishist 573242, which this server treats as periodic, so the live sample hardly separates the two readings).

## Owner ruling

- The mentor withdrew its approval at 09:08 (G-37 criterion 3 failed: live direct hits did not trigger) and sent the
  claim to the owner as Q-mb-2. The owner ruling of 2026-11-13 (Q-mb-2, option a: any damage dealt, as the tooltip
  says) is now the G-37 criterion 3, and the fix stays. The live split (124 of 177 live Parasites applications follow
  a periodic-class hit within 50 ms; 1 of 95 direct hits proc'd) stays as context only.

## Decision

- 560730 rolls on every own damaging hit, outside the periodic branch. 561319 ("Periodic damage dealt") keeps its
  periodic-only scope: its roll is split from 560730's, not moved. CoA script only; no shared engine code, no other
  class.

## Consequences

- The direct Glacial Impact proc entry of 560730 is expected inside the band (3%-7%), the periodic Blight entry stays
  inside it, and the baseline without the talent reads no Parasites.
