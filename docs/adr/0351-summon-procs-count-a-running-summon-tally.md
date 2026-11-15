# 0351. Summon procs count a running summon tally

- Status: accepted
- Date: 2026-11-13

## Context

Unrelenting Army 705747 / 707880 ("a $h% chance to animate a Lesser Zombie") and Muck Summoner 806086 ("an $h%
chance to summon $806087s1 Rotlings") spawn creatures through the Necromancer `Summon` helper
(AscensionNecromancerSummons.cpp:334), which casts no spell. A proc entry counted only spell casts, spell damage or
melee attacks, so these chances had no event to count. `owned_creature_count` reads living creatures and misses one
that expired or was evicted between reads. Cast-trigger proc entries also had no baseline arm.

## Options

- Read `owned_creature_count` after every attempt: misses evictions and expiries inside an attempt, and costs a read
  per attempt.
- Count summons in the harness as they enter the world, keyed by owner and entry.
- Count the timeline's spawn events: the timeline recorder is off outside timeline scenarios.

## Decision

- The harness keeps a running count, keyed by the player and the creature entry, of creatures entering the world with
  that player as owner, else summoner, else creator (`SummonCounter`, recorded from `OnCreatureAddWorld`, cleared
  with the run and the actors); the metric `owned_creature_summon_count` (`entry`) reads it. This is recording, not
  gameplay.
- A proc entry may count it: `event_metric: "owned_creature_summon_count"` with `event_entry`, on a cast trigger only.
- `baseline: true` on a cast trigger casts it before the passive is learned in part 1; the judge already leaves those
  trials and events out and alerts on any baseline event.
- `trials_per_attempt` divides the scheduled casts, and aura 53 SPELL_AURA_PERIODIC_LEECH counts in the tick spacing
  as aura 3 does (Harvest Plague's ticks are the trials).
- Spell damage metrics also take `resisted` (the log's resisted amount), for an unresisted amount read.
- Templar `generate --class 19` and `--stack` stay byte-identical.

## Consequences

- Unrelenting Army and Muck Summoner are proven by counted rates with a baseline; the Rotling explosion and the
  zombies' duration remain their own claims.
- A creature that enters the world for another reason with the player as owner (a pet resummoned) also counts: scope
  each entry to one creature entry.
