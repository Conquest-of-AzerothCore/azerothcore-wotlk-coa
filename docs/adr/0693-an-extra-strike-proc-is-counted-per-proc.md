# 0693. An extra-strike proc is counted per proc

- Status: proposed
- Date: 2026-11-15

## Context

Brushin' Off The Dusk 681329 and 681488: "Your off-hand auto attacks now have a $h% chance to strike 2 (3)
additional times and grant allies Replenishment." The strike counts had no label. No kind counts the strikes of one
proc: `strike_bursts` counts a minion's hits around a command, and a `hit_ratio` proc rate counts swings.

The approved design counted bursts of main-hand melee swings (a harness read over `actor.meleeHits`), on the reading
that 681392 is DBC effect 19 ADD_EXTRA_ATTACKS. The server rewrites 681392 and 681489 at load
(AscensionWitchHunterCompletion.cpp:247-254): effect 0 becomes SPELL_EFFECT_WEAPON_PERCENT_DAMAGE 100% at the enemy,
DmgClass melee, off-hand weapon required. Their strikes are spell hits (spell damage logs), not melee swings, so a
melee-swing burst read would count none of them.

## Options

- The designed harness read `melee_burst_count` (bursts of melee swings with one stamp): it cannot see spell hits.
- A burst read over stamped spell damage events: harness C++ that the counts below make unnecessary.
- Existing reads only: each proc casts the Replenishment of the same tooltip, 1257670, once; the strike spells'
  casts and landed hits at the dummy are counted against those casts.

## Decision

A kind module `extra_strikes` (ADR 0581). Without the talent (control) and with it learned (treatment), the caster
auto-attacks the dummy while dual wielding; each arm reads its off-hand and main-hand damaging swings, the
`proc_marker` casts and, per `strike_spells` entry, its casts and landed hits. The verdict is ok only when the
control neither procs nor strikes and the treatment's landed strikes are exactly `strikes` per proc, each strike
cast landing. The proc share is reported with its Wilson interval, not judged: the band needs 5973 off-hand hits at
10% and 10618 at 20%, about 25 to 45 ten-minute scenarios per rank, and the chance clause keeps its data label.
No harness file changes.

## Consequences

- Tests: `ExtraStrikesTests` (kinds/test_extra_strikes.py); page `docs/kinds/extra_strikes.md`.
- Entries: `681329 behaviour_metric_delta extra_strikes` (2) and `681488 behaviour_metric_delta extra_strikes` (3),
  counting 681392 and 681489 against Replenishment 1257670.
- `behaviour_kinds()` gains `extra_strikes` at ORDER 44; the finished classes' scenarios are unchanged.
- Number provisional: shared ADRs are numbered at merge.
