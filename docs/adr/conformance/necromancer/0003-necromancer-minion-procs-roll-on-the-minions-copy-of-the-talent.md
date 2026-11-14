# 0003. Necromancer minion procs roll on the minion's copy of the talent

- Status: accepted (mentor approval of fix note F-b1-1, 2026-11-13)
- Date: 2026-11-13

## Context

Depravity 638403 ("gives their critical melee auto attacks a $h% chance to trigger Bone Club") and Plague Horde 802986
("Damage dealt by your Undead minions now has a $h% chance to cast Plague Horde on themselves") never fired: 0 Bone
Club 801241 in 4175 forced Ghoul melee crits and 0 Plague Horde 807653 in 1446 Ghoul hits per run (Necromancer B1,
build 08e9c4b90bec and again on bbd182061fb0). `AscensionNecromancerEvents.cpp` rolled both with `Chance(player,
talent)`, which requires `player->HasAura(talent)`. Both talents carry only SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS
(190) effects, so their aura sits on the minions and never on the player. The live server fired both: the combat logs
hold 317 Bone Club hits by Ghouls and 31124 Plague Horde lines on minions.

## Considered options

1. Make `Chance` accept the aura on any minion. Rejected: it changes every other `Chance(player, ...)` site.
2. A variant that reads the aura on the minion that dealt the hit. Chosen (mentor terms: leave `Chance(player, ...)`
   unchanged elsewhere).

## Decision

- `MinionChance(player, holder, talent, multiplier, cooldown)` (`AscensionNecromancer.cpp`) rolls like `Chance` but
  requires `holder->HasAura(talent, player GUID)`; the per-player cooldown state and the chance spell modifier stay.
- Depravity and Plague Horde roll with the acting minion as the holder.

## Consequences

- Regressions: the Depravity and Plague Horde proc entries (forced Ghoul crits and Ghoul hits, baselines without the
  talent, proc rates judged to the band, ADR 0346).
- Observation, not changed: `Chance(player, 503740)` (Ghoul Mastery, `AscensionNecromancerEvents.cpp:173`) and
  `Chance(player, 531128, cost)` (Overwhelming Force, `:169`) name talents with only effect-190 effects too, so those
  two script rolls never pass; both talents also proc natively on the minion (`AscensionNecromancerContracts.cpp:52-56`),
  which is what the Overwhelming Force proof measured.
