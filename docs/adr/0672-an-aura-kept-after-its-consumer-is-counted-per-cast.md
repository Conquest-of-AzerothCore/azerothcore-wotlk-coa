# 0672. An aura kept after its consumer is counted per cast

- Status: proposed (provisional number, assigned at merge)
- Date: 2026-11-15

## Context

Witch Hunter Lightbringer 680538: "This effect has a 25% chance to not be consumed by Purifier's Edge." The
consumption is `AfterCast` code (AscensionWitchHunterAbilities.cpp:418-422): a Purifier's Edge cast removes 680539
unless `roll_chance_i(25)`. No existing kind measures an aura surviving a cast at a rate: `proc_rate` counts proc
events, `oath_consumption` one consumption, `hit_ratio` rates count hits. The roll is a script constant, so a forced
roll (`SPELLMOD_CHANCE_OF_SUCCESS`) cannot reach it, and the G-20 band at 25% needs 12443 trials, beyond one scenario.

## Options

1. A forced roll: not possible, no spell modifier changes a constant script roll.
2. A kind module that sets the aura before each cast, reads it after, and pools identical parts.

## Decision

Option 2, kind `aura_keep_rate` (kinds/aura_keep_rate.py): per trial `set_aura` (precondition fixture, named in the
verdict), the cast at the dummy through `behaviours.hit_ratio_cast`, then `aura` and `cast_failure`; a control arm of
another spell outside the consumer's mask must keep the aura every time; parts pool through `POOLED_JUDGE`, judged by
`compare.rate_judgement` and `banded_rate`. Below the band's trials the verdict is G-20 step 1 with its interval. The
contract states the residual failure probability of a conformant server (normal approximation). An optional off-hand
item equips the class file's `off_hand_weapons` entry for a consumer with SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON.

## Consequences

- Lightbringer 680538 claim 183: pilot 20261115-072903 (one part of 320): 88 kept, 27.5% (Wilson 99% 21.6% to 34.3%).
  Pooled proof, 59 parts of 320 (18880 casts), residual failure 1.6e-4 per run: see the Witch Hunter ledger for the
  counted pair.
- The Witch Hunter class file gains `off_hand_weapons` (Worn Shortsword 25): Purifier's Edge needs an off hand
  (AscensionWitchHunterCompletion.cpp:157-158 clears the attribute for Dusk Blade only).
- No server mutant can alert this kind (the roll is a constant); the seeded tests cover the alerting readings.
- Shared files unchanged; Templar and Necromancer generate byte-identical (no entry of this kind).
- Test: kinds/test_aura_keep_rate.py.
