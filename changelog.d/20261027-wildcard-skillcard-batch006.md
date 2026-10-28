# Wildcard card repairs: batch006

## 275965 — Master's Meatshield

Before: The passive had no execution route to copy Drain Life healing to its pet-heal helper. Native leech healing does not generate an ordinary healing proc for this card.

Written change: A registered healing hook forwards the Drain Life self-heal amount before absorbs/overhealing and PvE/PvP power to the native pet-heal helper. Native guardian/charm priority is retained; the target must be alive, owned, in the same map and an allowed beast/dragonkin/demon/elemental/undead type. The helper has explicit zero coefficients to prevent a second default flat-healing coefficient. No pet, another owner, unrelated healing and dead pets do not qualify.

## 277588 — Thousand Cuts

Before: The Hurricane-triggered buff had no activation route. Its Rogue-family periodic modifier did not cover cross-class bleeds/poisons or direct poison damage.

Written change: Hurricane damage applies the existing native stacking buff. Spell-mod eligibility follows poison dispel type or bleed mechanic across classes. The existing periodic modifier is retained; a guarded second direct-damage modifier covers direct poisons. Native stack cap, duration and percentage remain unchanged; direct and periodic amounts use their corresponding modifier operation.

## 280040 — Envenomed Weapons

Before: The native nearby-allies aura existed but had no proc events, and its damage child lacked the tooltip-authored SP/AP coefficient row.

Written change: Restore the native 5% damage proc for affected aura holders, including periodic damage. Native area targeting and proc dispatch choose the caster/target. The child receives exactly 0.1 SP and 0.1 AP through spell_bonus_data while keeping its native base and level contribution. Native same-aura recursion prevention is retained.

## Pending cards

- 271400: Maledictive Assault: reduced-damage value and complete Bear-form secondary-target contract are not established; no replacement percentage or cleave behavior authored.

- 278420: Maelstrom: native40-stack and70%buff text exists, but the final result-producing damage child and complete overload/consumer chain are not verified; no invented payload.

## Delivery and verification

Requires the updated source and pending world migration `rev_20261027_05_wildcard_skillcard_batch006.sql`. All earlier migrations and repairs remain part of the same future new PR. No SQL was applied locally.

Changed-file C++/SQL codestyle passed. Installed DBCs, fresh scoped acore_world data, native modifier operations, native pet target selection, self-leech healing stage and proc ownership/recursion paths were inspected. No compilation or gameplay/server tests were run under the user's existing restriction; all three repairs remain FIXED_UNVERIFIED. Runtime qualification is required for party proc attribution/scaling, cross-class direct/periodic modifiers, pet/charm selection and forwarded-heal modifiers.
