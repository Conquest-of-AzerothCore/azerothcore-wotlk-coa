# 0028. Owner ruling Felsworn O-32: Tyrannical Resolve ends with its own Felfire Blast

- Status: accepted (owner ruling Felsworn O-32 (2026-11-24))
- Date: 2026-11-24

## Context

Tyrannical Resolve 804823, server DBC text: "When this ends, you unleash a Felfire Blast that leeches health from
nearby enemies based on how many times you took damage with the effect active."

Server before: the class aura script (`AscensionFelswornAuras.cpp`, removal of 804823) cast Burning Hatred 807347
(Burning Hatred 805239's own proc, HEALTH_LEECH, all schools) on every valid enemy within 10 yd for 1% of the caster's
maximum health per hit taken, capped at 50 hits (commit 46bf8121e5, a local policy "where no coefficient was
recovered"). Measured 200 at one hit and 600 at three, heal equal to damage (L1 pair, night question N-6). Felfire
Blast 804825 was never cast.

Data: 804825 Felfire Blast, Effect[0] SPELL_EFFECT_HEALTH_LEECH x1.0, SchoolMask 36, TARGET_SRC_CASTER /
TARGET_UNIT_SRC_AREA_ENEMY, RadiusIndex 13, MaxAffectedTargets 20, DmgClass 2: BasePoints 59, RealPointsPerLevel
1.44 from SpellLevel 59, DieSides 2, so 61 to 62 at level 60. 804823 Effect[0] is aura 108 SPELLMOD_DAMAGE +2%
(BasePoints 1, DieSides 1) on 804825's class flag, StackAmount 100, stacked by 704615 -> 707519 (+1 per hit taken).
The class contract makes that effect a dummy, and the stacks would leave the caster with the aura before the blast.

The owner ruled (Felsworn O-32 (2026-11-24)): the end explosion is Felfire Blast with its own data values (about 62, 65 and 67), replacing
1% of maximum health per hit taken.

## Decision

On the removal of 804823 while the caster lives, the class aura script counts the hits as before (script value 804823,
one per absorbed damage event), caps them at 804823's StackAmount, stores hits x 804823 Effect[0] (2) as a percent in
the caster's Felsworn state, casts 804825 on the caster (its own area selects the enemies) and clears the percent.
`felsworn_scaling::ModifySpellEffectBaseValue` raises 804825 Effect[0] by that percent. It is the shape the class
already uses for Carve (`carveSteps`, a state set around a cast).

## Consequences

- The blast deals 804825's own points times (1 + 0.02 x hits): 62 to 63 at one hit, 64 to 65 at three, 67 to 68 at
  five at level 60, and heals the caster by the damage. It now also fires after an end with no hit taken, at its own
  61 to 62; the 807347 amount was 0 then and nothing was cast.
- The percent is applied to the base value, so it multiplies other SPELLMOD_DAMAGE modifiers of 804825 instead of
  adding to them as stacked spell modifiers would. No Felsworn code applies another one (Tyrant's Rage 804824 is only
  a script value key here).
- 804825 is DmgClass melee without SPELL_ATTR2_CANT_CRIT: it can miss and critically strike, which 807347 could not.
- Keyed to 804823 and 804825 by id; both are Felsworn spells and no other class reads them. 807347 stays Burning
  Hatred's proc (`AscensionFelswornEvents.cpp`). No engine, SQL, DBC or client text change.
- Regression: `804823 end_leech` (counts judge): arms of 1, 3 and 5 hits, each trial exactly one 804825 hit on the
  striker and no 807347 hit, the 804825 damage rising strictly with the hits and the heal equal to it; 64481 removes the
  blast's melee crit, 984948 its miss and 823764 the striker's partial resistance (Fire and Shadow) in every arm.
- The blast's Fire and Shadow school can be partially resisted, which the all-school 807347 could not.

## Amendment: the regression judges the amounts (2026-11-24, review fw-rf3 I-1 and M-3)

The rise alone did not tell the ruled amounts from the rejected option (N-6 option A, 1% of maximum health per hit,
also rising). `804823 end_leech` now gives every arm a band of the 804825 damage, from 804825's own data and 804823
Effect[0] only: zero hits 61 to 62, one 62 to 63, three 64 to 65, five 67 to 68 (61 or 62 times 1 + 0.02 n,
truncated). A zero arm takes no strike and still reads one blast at its own points, the end with no hit taken above.
The bands of one, three and five are disjoint and ordered, so the strict rise is dropped from the judge. The counts
judge gained optional per-arm bands and arms of no strike for this (`behaviours.py`, `compare.py`); an entry that
states neither generates as before.
