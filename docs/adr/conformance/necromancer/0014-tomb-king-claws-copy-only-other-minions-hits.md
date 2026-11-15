# 0014. Tomb King claws copy only other minions' hits

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Tomb King 805044: "While active, all of your Undead minion's attacks deal an additional $800027s1% of the
damage dealt as Plague damage." Putrid Aura 800027 reaches the player and the minions (Effect 190). The event handler
copied Putrid Claws 570050 for every damage of an actor holding 800027 under the `(minion || own)` gate
(AscensionNecromancerEvents.cpp:97-100), so the player's own swings and spells and the Tomb King's own swings clawed
too. Side c's scope entries (feat/coa-necro-m-c, pair 20261113-063138 / -063209) read those player-sourced and Tomb
King-sourced claws; live logs show none from players and none from the Tomb King (0 of 2,289 of its swings). The mentor
approved fix FN-mc-2 on 2026-11-13.

## Decision

- Only the 570050 branch changes: the copy is cast when the actor is an owned minion and not the Tomb King 50320. The
  `(minion || own)` gate at :97 stays (other branches use "own"), and Diabolical's 570050 copy stays.

## Consequences

- Regression (class file): player_swings, player_spell and tomb_king_swings read 0 Putrid Claws with the Tomb King up
  and 0 without it (the control phase); player_spell_lands shows the player's Lichfrost landing; putrid_with keeps a
  Ghoul's claws (at least one).
- The Tomb King share claim 262.1 stays status 5 (Q-a1-5); its magnitude read may move with the player's claws gone.
