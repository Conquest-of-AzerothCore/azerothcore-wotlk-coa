# 0245. Class-file cast auras in hit and periodic-total scenarios

- Status: accepted
- Date: 2026-11-12
- Extends: the `cast_auras` class-file section (ext2, 682d4a9427)

## Context

Since ADR 0243, Blade of Faith's ticks can crit. Its hit scenario (803880 hit_mean, claim 361) and its periodic-total
scenarios read the mean non-critical tick and the total, so a crit chance above 0 would leave the reads to selection
after the fact or move the totals. The mentor asked that Blade tick scenarios force a 0 crit chance. `cast_auras` set
auras before a spell's cast in value scenarios only.

## Decision

`hits.hit_parts`, which builds the hit and periodic-total scenarios, adds `cast_aura_steps` of the cast rank to the
fixtures before every cast. The class file gives each Blade rank 803872-803880 the aura Reduce Critical Strike Chance
-100% 64481 (aura 52, -999% weapon crit). Ranks without a `cast_auras` entry regenerate byte-identical.

## Consequences

- The 61 Blade hit, periodic-total and value scenarios now set 64481 before each cast, and were rerun twice on the
  final build.
- Side a's Focused 300524 `blade_of_faith` hit ratio needs 64481 in both arms; the integrator adds it (r2-locks.md).
