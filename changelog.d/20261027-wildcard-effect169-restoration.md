# Wildcard spread-aura restoration

Source implementations; runtime verification pending.

- Spreading Plague (270358): its spread helpers had no native effect handler. Original-caster Infected Blood and Rabies now spread through the reviewed eight-yard native reapplication recipe.
- Bloody Business (277162): the Mangle sequence had no working proc controller or spread handler. The native two-stack marker now triggers Pounce spreading on the third completed Mangle without refreshing the sequence window.
- Corrupted Blade (281492): its existing activation reached an unhandled spread effect. Corruption/Jadefire now propagate within the tooltip ten-yard radius with native application limits, excluding totems and controlled players; alias slots cannot spread the same aura twice.
- Blaze (281749): Fire Blast lacked the bound proc controller and spread effect. Completed Fire Blast now spreads the caster-owned Immolate variants using aura-only application, periodic snapshots and zero periodic crit chance on the copies.
- Virulent Dominion (288985): Pestilence spreading and Scourge Strike marker activation lacked bindings; Unholy Blight was absent from the crit eligibility mask. These paths are now wired, with original-caster disease-tick charge consumption and preserved Unholy Blight periodic snapshots.

Shared native effect169 dispatch is guarded to six reviewed helper IDs and their Misc1/Misc3 recipes. It uses fresh native aura duration/tick timing; private remaining-duration and hidden-script-state transfer are not decoded. Other consumer variants and effect170 remain unchanged. Nature's Reach keeps its dedicated implementation. Potential beneficiaries are not credited as repairs.

Pending world migrations: rev_20261027_27_wildcard_spread_aura.sql and rev_20261027_28_wildcard_spread_dependents.sql. Neither was executed. Formatting checks only; no compilation or gameplay testing.
