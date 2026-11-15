# 0212. An ally cast target in taken_hit and cast_applies_aura

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0153 (taken hits), ADR 0126 (expiry pairs)

## Context

Binding Scripture 801457, claims 315-317: "Healing an ally now redirects ... and reduces your damage taken by
$707307s1% for $705309d, stacking $705309u times. Healing yourself does not trigger this effect." Its script
(AscensionTemplarEvents.cpp:79-80 and :164-166) casts 707307 on the Templar only after an effective heal on a raid
member other than the Templar. A damage-taken claim is proven by an applied hit (ruling 4, ADR 0153), and a duration by
its expiry pair; neither `taken_hit` nor `cast_applies_aura` had an ally to heal, so the earlier entry set 707307 with
`set_aura` and read the damage-taken calculation, a readback.

## Options

1. Set 707307 with `set_aura` before the strikes. It skips the script path, which mech condition 4 forbids.
2. A new kind for an ally-triggered aura. It repeats the strike, read and expiry machinery.
3. Let the casts of both kinds target `ally`: the grouped ally player is added only then.

## Decision

Option 3. A `taken_hit` arm cast (opening, before or after the strikes) and a `cast_applies_aura` `cast_target` may be
`ally`. The scenario then has the ally player fixture, grouped with the caster right after the learns (`taken_hit`) or
the base steps (`cast_applies_aura` readback and expiry). `taken_hit` gains `ally_health_pct`: the ally is set to that
percent of the fixture maximum before every cast at it, so a heal is effective; it is refused without a cast at the ally
or outside 1-99. `cast_applies_aura` already sets its cast target's health with `cast_target_health_pct`. Entries that
cast at no ally regenerate byte-identical.

## Consequences

- Binding Scripture on build 861e0e1e6bee, counted 20261112-012025 / -012146: one heal of the grouped ally reads 1045
  against 1100 (0.95); four heals read 935 (0.85, the cap of 3 stacks; an uncapped fourth would read 0.80); a heal of
  the Templar itself reads 1100 (1.00); 707307 ends after 9750 and by 10375 ms after the heal, stated 10000.
- Seeded tests: the ally is grouped before the first heal and set to 50% before each; no ally without an ally cast;
  `ally_health_pct` without an ally cast is refused; an unreduced, an uncapped and a two-stack reading alert, as does a
  reduction after a self heal.
