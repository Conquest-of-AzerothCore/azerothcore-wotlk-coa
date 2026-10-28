## Campaign011 group2 — resumed session

- 280225 Astral Reconstitution: implemented. Shared354nativeincoming-damage branch now forwards native30%damage taken to mana helper280226on owner, including periodic damage. Five native charges retained and consumed only by accepted damaging events; outgoing-only events excluded.
- 280365 Apotheosis: implemented. Shared354nativeoutgoing-damage branch now heals owner for native100%damage using280366. Native10%maxhealth-per-second self-drain retained; self-damage explicitly excluded from healing proc so cost is not refunded. Zero extra stat coefficient, no charge changes.
- 280375 Champion of the Sun: implemented. Individually audited shared354implementation: native50%melee-auto damage forwarded to Holy child280376,100%proc rate; weapon abilities/ranged attacks excluded, native duration retained. Root credited only after selected-root DB/DBC/source audit.
- 281050 Infused Aegis: implemented. Native354incoming melee event forwards native100%event amount to Arcane counterattack281051. Requires attacker in native front arc. Aura-local enemyGUID timestamps enforce1000ms perenemy, allowing simultaneous different attackers; native buff lifetime bounds state, no global cooldown or stat coefficient.
- 200809 Consecrated Weapon: blocked. Previous native enchant/stat grants retained. Weapon-speed Holy proc formula remains underdetermined by tooltip bounds and conflicting Flametongue donor text; no repeated broad investigation or invented interpolation.

Cumulative107/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
