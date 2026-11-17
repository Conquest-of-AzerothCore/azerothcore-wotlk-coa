# 0182. Cast-applies-aura forces a crit

- Status: accepted
- Date: 2026-11-11
- Extends: ADR 0126 (expiry pairs) and ADR 0142 (cast-applies-aura control arms)

## Context

Scarlet Champion 805415: "Your damaging critical strikes now increase your Holy damage dealt by $805416s1% for
$805416d." The duration claim "for $805416d" was a DBC readback (`spell_duration`). The expiry pair of a
`cast_applies_aura` entry proves a stated duration from a real cast, but its scenario keeps the class fixture's crit
rating, so a cast that applies its aura only on a critical hit applies nothing, or applies it on a random share of
casts.

The trigger, metric-delta and duration kinds already force a crit with `force_crit`, which sets
`melee_crit_rating` or `spell_crit_rating` to `FORCED_CRIT_RATING` on the player fixture. The class fixture's hit
and expertise ratings already remove misses, dodges and parries.

## Options

1. Set 805416 with `set_aura` and read its expiry. That proves the DBC duration of a set aura, not the aura the
   critical hit applies.
2. A trigger `duration_delta` entry. It measures a change in a duration, not the duration itself.
3. Give `cast_applies_aura` the same `force_crit` field, applied in its readback and its expiry scenario.

## Decision

Option 3. `force_crit` needs a `cast_spell` and a known rating; otherwise the entry is refused. Without the field the
player fixture is unchanged, so existing scenarios regenerate byte-identical.

## Consequences

- Scarlet Champion reads 805416 at 19997 ms right after one forced-crit Argent Blade, present 19500 to 19575 ms after
  the cast and absent 20500 to 20625 ms after it.
