# 0738. A metric delta expiry can be judged for its direction

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 297.0 (Unbroken 707407, "This degrades slowly over time, and while out of combat.") states a decay
without a rate: the server takes 5% of the stored attack power every 2 s in combat and 10% out of combat
(`AscensionWitchHunterEvents.cpp:631-638`), numbers the tooltip does not give. A `metric_delta` expiry reading must
match a stated value. Gap design O3 (c13 gap designs), mentor ruling D-201.

## Options

- An opt-in `expiry_below_after`: the expired reading must lie below the after reading and at or above
  `after_expiry_expected` (the floor).
- Judging the server's 5% and 10% rates: they are not the tooltip's (G-37: the server is not the expectation).

## Decision

The opt-in direction judge, in `compare.judged_metric_delta` behind the model key the option writes. The before and
after readings keep their judge.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); no entry of
  theirs writes the key.
- Seeded tests: an expired reading between the floor and the after reading passes, at or above the after reading or
  below the floor alerts; the before and after readings still alert on their own; the mutant without the option (the
  equality judge) alerts on a real decay; the option without an expiry read or with a floor at the after floor is
  refused.
- Witch Hunter: `707407 behaviour_metric_delta decays`. The pilot read 282, 357 and 344: a gain of 75, then 62 after
  4000 ms, two 10% steps, the server's out-of-combat rate; the caster's combat state is not read, so the entry
  claims the decay over time, not which of the two rates applied.
