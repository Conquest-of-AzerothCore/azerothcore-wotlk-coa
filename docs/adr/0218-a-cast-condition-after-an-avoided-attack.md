# 0218. A cast condition after an avoided attack

- Status: accepted
- Date: 2026-11-12

## Context

Sacred Swing 572769, claim 210: "Only usable after avoiding an attack." Its CasterAuraSpell is Recently Parried or
Dodged 681170, which Keeping the Oath 92109 triggers on a taken dodge or parry (spell_proc HitMask 48,
rev_20261001_04_templar_keeping_the_oath_avoid.sql). Every other entry that casts Sacred Swing sets 681170 with
`set_aura` (`required_aura_steps`), so no entry showed the avoidance itself opening the cast.

## Decision

`cast_condition` gains `condition: "avoided"` and `learn` (spells learned beside the entry's spell). The scenario adds
an aggressive, rooted attacker (creature 36, Self Root Forever 42716) 3 yd in front of the caster. Blocked: the attempt
before any attack. Allowed: Evasion 26669 on the caster, one engaging swing interval, then 6000 ms of the attacker's
swings, the dodges read, then the attempt. The attempts set no caster aura. Other conditions regenerate byte-identical.

## Consequences

- Sacred Swing on build 861e0e1e6bee: refused before any avoided attack (22 SPELL_FAILED_CASTER_AURASTATE), through
  after the dodged swings (3 dodges), with Keeping the Oath learned.
- Seeded tests: the attempts set no 681170; the allowed attempt follows the attacker's swings; a server that lets the
  cast through unconditionally alerts on the blocked reading.
