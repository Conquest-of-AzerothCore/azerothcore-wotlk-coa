# 0061. Bone Smash is read over the Colossus swing after its armored flat

- Status: accepted
- Date: 2026-11-13

## Context

Claim 73.1, Raise: Decaying Colossus 500989 "dealing Weapon Damage plus ${$505229m2+$505229ppl2} to all enemies in
front of it", was data only (`500989 effect_value 505229e1 #1`). Design review/c9-73-design.md, approved by the mentor
(cycle 9, 21:32) with three conditions: armor handled (zero-armor dummy or the flat removed after the run's armor
factor), the per-level term read from the server DBC, the band by the tool's rule. Server DBC set (coa-dbc-viewer
record --data /srv/coa/server-data/dbc --table Spell --id 505229): Effect[0] NORMALIZED_WEAPON_DMG BasePoints 0,
Effect[1] SCHOOL_DAMAGE BasePoints 99 + DieSides 1 = 100, EffectRealPointsPerLevel[1] 0.0, EffectPointsPerComboPoint[1]
0.0, EffectBonusMultiplier[1] 0.0, SchoolMask 1, DmgClass 2, SPELL_ATTR0_SCALES_WITH_CREATURE_LEVEL, SpellLevel 20.

## Decision

A `minion_swing_ratio` entry `weapon_plus`: Summoning Adept 92123 learned, a real 500989, 80 Command: Undead 504868
4500 ms apart in each of 2 pooled parts, the Colossus 50115's non-critical 505229 hits over its own plain swings after
the flat 100 scaled by the read `armor_reduced_damage` (ADR 0631), expected 1.0 in the 5% ratio band. The caster holds
2500 spell power (harness fixture): it narrows the swing spread and leaves 100 at about 11% of a hit, so a missing
plus reads about 0.87. The `effect_value` read stays on the claim as a readback.

## Consequences

- A creature-level scaled plus (the open question Q1 of the design) would read above 1.0; the uncounted pilot
  20261113-205010 read 0.981 (raw), inside the band and below 1.0: the plus does not read larger than 100.
- The cone breadth ("all enemies in front of it") is not measured by a second dummy; the claim's reason says so.
