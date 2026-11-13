# 0563. Frozen Bodies' 10-stack Glacial Impact crits without a second 1.5x

- Status: accepted
- Date: 2026-11-13

## Context

Frozen Bodies 712434 (Spell.dbc): "Increases the damage of your next Glacial Impact by $s1% for $d, stacking $u
times. Reaching 10 stacks causes your next Glacial Impact to critically strike for 50% increased damage."

Commit 28458f596e (PR #10573, "follow-up batch fu1", sub-fix for issue #10025) forced the crit at the 10-stack cap
(`OnSpellCritChance`, AscensionNecromancerAbilities.cpp) and also multiplied Glacial Impact 707592's Effect[0] base
value by 1.5 (`ModifySpellEffectBaseValue`, AscensionNecromancerContracts.cpp). The tooltip is ambiguous: either a crit
plus 50% more, or the crit itself is the "50% increased damage" (spell crit multiplier 1.5).

Live decides (conformance rule G-11; source: all 2878 live Glacial Impact 707592 events are crits; pairs of
consecutive hits on one target at 9 then 10 stacks, n 14, median ratio 1.031, 8 of 14 within 0.97-1.031; a second
x1.5 would give about 1.55). The mentor ruled after the owner, with no objection: the crit is the 50%.

## Decision

- Drop the extra x1.5 on base damage. Keep the forced crit at the 10-stack cap.

## Consequences

- The 10-stack hit is the 9-stack hit times the stack spellmod (about +3%), with a crit.
- Scenario necromancer-frozen-bodies-max-stacks-10025 now expects a ratio of 1.0 to 1.06 against the 9-stack crit.
- Class file entry 707562 ten_stacks_ratio: control 9 stacks, treatment 10 stacks, both crit, expected 1.03.
- Reverses the damage half of #10025/#10573; its crit half stands.
