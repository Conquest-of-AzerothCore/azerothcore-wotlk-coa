# 1271. Spell clamp casts option sizes the edge arms

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-24

## Context

The `attacker_miss_share` `spell_clamp` variant ([ADR 1217](1217-attacker-miss-share-judges-a-spell-hit-reduction-at-the-hit-clamp.md))
casts a fixed N = 826 per arm, the smallest count for which four edge arms per pair stay missless on a correct server
at most 0.1% of the time under an assumed 1% edge miss chance. Felsworn Armaments of the Legion 706266 and 707844
("Reduces your chance to be hit by spells by $s1%", 2 and 4 points) measured exactly the stated reduction in both runs
of a pair, but the edge arms read 0.94% of casts as misses (4 to 11 per edge arm), which leaves 0.16% per pair at
826 casts: above the 0.1% limit, so the claims were withheld.

## Options

- Raise the fixed N for every entry: moves the finished Sun Cleric scenario (Sun Shield 300348) and its digest.
- Size N from a residual or a miss share in the entry: a new judging input, and the miss share is a reading.
- An opt-in whole `casts` count per arm, never under the default N.

## Decision

The third option. An entry of the variant may write `casts`, a whole count of at least 826; every arm casts that many
times and the model's `casts` follows it, so the existing judge (an arm short of the count is unmeasured) applies
unchanged. A count under 826, a fraction, a string or a boolean is refused. Felsworn writes 1100 for 706266 and 707844:
four edge arms per pair missless with probability 0.012% at the 0.94% share read (0.0063% at 1%).

## Consequences

- Absent by default: an entry without `casts` generates the same scenario and model as before; the finished classes
  regenerate byte-identical.
- No judge, tolerance, evidence class or closing key changes; only the arm length and the contract's residual text.
- Seeded tests (`kinds/test_attacker_miss_share.py`): a sized entry casts the count on every arm and states its
  residual; the default count equals no option; short or non-whole counts are refused; a sized entry passes, the
  clamp-miss and missless-edge mutants alert, and arms at the default count are unmeasured against a sized model.
- A 1100-cast Felsworn entry has 8,856 steps (8,800 cast and wait steps), under the 10,000-step cap; above 1,243
  casts the same entry is refused by the existing cap check.
