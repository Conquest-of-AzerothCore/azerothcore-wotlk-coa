# Wildcard restoration group 1

## 284374 â€” An Honest Mistake

Before: No active proc/script route in shared world.

FIXED_UNVERIFIED: Spell misses grant native5%hit/haste buff; auto attacks excluded.

## 271746 â€” Locust Ranger

Before: No active proc/script route in shared world.

FIXED_UNVERIFIED: Steady Shot checks own Serpent Sting and active Wild Quiver, then fires native60%weapon shot.

## 273318 â€” Blademaster

Before: No active proc/script route in shared world.

BLOCKED: Root promises Death Strike cleave but helpers describe incompatible Shield Slam/Tactical Mastery contracts.

## 281701 â€” Shaken

Before: No active proc/script route in shared world.

FIXED_UNVERIFIED: Fear applies native marker; native3second clock spreads25%slow/5%stats around victim with original-caster hostility.

## 281744 â€” Echoed Incinerate

Before: No active proc/script route in shared world.

BLOCKED: Ambiguous helper level formula must be reconciled before a complete secondary damage implementation is credited.

Requires pending world migration `rev_20261027_08_wildcard_restoration_group1.sql` and the registered card-restoration source. Formatting checks only; no compilation, gameplay tests, live SQL or deployment. All implementations are runtime-unverified.
