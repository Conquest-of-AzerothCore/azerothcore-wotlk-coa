# 0345. Necromancer summons-only auras recalculate through the owned aura

- Status: accepted (mentor approval of fix note F-b1-2, 2026-11-13)
- Date: 2026-11-13

## Context

Death and Ice 560012: "While a Skeletal Mage is active the critical strike chance of your Undead minions is now
increased by $523613s2%." Learned before a Skeletal Mage was raised, a Ghoul read 5% crit with the mage up (stated
15%); learned with the mage already up it read 15%. `aura_ascension_necromancer_lifecycle` sets the amount from
`Count(player, {50075})` (`AscensionNecromancerAuras.cpp:60-61`), and the 500 ms loop recalculates it through
`player->GetAura(id)` (`AscensionNecromancer.cpp:393-397`). 560012 is a summons-only (effect 190) aura: the harness
read `owned_aura` 1 and `aura` 0 on the caster after the learn (pair 20261112-225239/-225417), so the lookup found
nothing and the amount kept its value at the learn.

## Decision

The recalculation looks the aura up with `player->GetOwnedAura(id)`, which also finds an aura the player owns without
holding it; for the auras the player holds itself it is the same aura.

## Consequences

- Regression: `560012 behaviour_metric_delta mage` (the Skeletal Mage raised after the learn: 5 then 15) with its
  controls `560012 behaviour_metric_delta crit` (the mage up in both phases) and the Ghoul alone (5).
- The other ids of that list get the same lookup; those the player holds are unchanged.
