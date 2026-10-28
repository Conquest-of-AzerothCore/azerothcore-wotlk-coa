# Wildcard card repairs: batch 004

## 270526 — Words of Healing

Before: The passive has no proc route to its critical-chance helper, so Borrowed Time supplies no card bonus.

Changed: Add the native helper's 30 percentage points at the direct-heal critical roll while a Borrowed Time casting-speed buff is active. Passive talent auras and the unrelated Chronomancer aura do not qualify; no lingering helper is applied.

## 277609 — Critical Serration

Before: The card has no active event route; native Piercing Shots only admits Hunter-family events, excluding the two Rogue attacks.

Changed: Route Shuriken Toss and Deadly Throw critical damage through the existing Piercing Shots delayed-bleed API. Read the active Piercing Shots talent percentage and native tick count; do nothing without that talent. Preserve caster ownership and existing bleed accumulation.

## 281542 — New Moon

Before: The passive has no event route and its refresh helper uses effect 198, whose dispatcher is EffectNULL.

Changed: On a successful non-instant damaging cast with a unit target, extend only that caster's existing Moonfire by the native helper's 1,000 ms. Triggered/instant casts are excluded. The once-per-cast hook avoids additional extensions for ticks or extra hits; no Moonfire is created and no unsupported helper is cast.

## 283090 — Corrupting Shadows

Before: The passive has no event route or trigger spell to apply Corruption.

Changed: Bind the existing registered Corruption application handler to landed Shadowburn damage, restricted to its verified Warlock family/mask. Reuse native known-rank selection and its rank-one fallback; do not create a second Corruption implementation.

## 284460 — Tribal Rage

Before: The passive has no event route; the two critical-event branches are not dispatched.

Changed: Dispatch melee criticals to the existing 2,000 ms Shamanistic Rage cooldown-reduction helper, and other direct damaging spell criticals to the existing 1,000 ms duration-extension helper. Periodic damage is excluded; the helpers retain native cooldown/aura behavior.

## Delivery and verification

Requires the updated source and pending world migration `rev_20261027_03_wildcard_skillcard_batch004.sql`. The migration adds three proc/script bindings; Words of Healing and New Moon use registered global spell hooks and need no proc row.

Changed-file C++/SQL codestyle and tracked whitespace checks passed. No compilation, automated gameplay tests, live SQL application, deployment or in-game validation was performed. All five repairs remain FIXED_UNVERIFIED. Fresh read-only acore_world data was inspected after MySQL became available.
