# 1210. An avoided proc trigger can count misses, with an attack balance

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Blessed Bulwark 680663 ("Avoiding an attack now has a $h1% chance..."): the handler rolls on every Miss,
Dodge or Parry (`AscensionSunClericEvents.cpp:72`, `PROC_HIT_MISS | PROC_HIT_DODGE | PROC_HIT_PARRY`), while the
avoided trigger counted dodges and parries only, so the misses' procs inflated the rate (0.2622 and 0.2632 against
0.25). The harness read `melee_missed_taken` (HITINFO_MISS per attacker) was approved by mentor D-175.

## Options

- Force the miss chance to 0: no harness fixture does it, and it would hide the handler's miss branch.
- Add the misses to the trials and check that every attack taken is a dodge, a parry or a miss.

## Decision

`count_misses: true` on an `avoided` trigger adds `<trials> missed` (`melee_missed_taken`) to the reading and to the held
baseline, and the proc model carries `attack_balance` (`{total, parts}`). `judge_proc` makes a counted part whose
`melee_attacks_taken` total differs from the dodged, parried and missed swings `unmeasured` (void), so a miscounted
outcome shows instead of being judged.

## Consequences

- Absent by default; the finished classes regenerate byte-identical.
- Seeded tests: procs on misses at the stated chance pass, a mutant that never procs on a miss alerts, one attack
  outside the three outcomes voids the part.
