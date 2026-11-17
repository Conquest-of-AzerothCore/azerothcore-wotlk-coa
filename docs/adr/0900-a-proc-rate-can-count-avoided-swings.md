# 0900. A proc rate can count avoided swings

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Dawn Knight 680497 ("Avoiding damage or dealing damage with auto attacks now has a $h% chance to grant you Dawn
Knight", claim 140.0) and Vengeful Intent 705534 ("or avoid an attack", claim 278.1) roll on a dodged or parried
attack taken (`AscensionWitchHunterEvents.cpp:120, 181-182, 204-205`). ADR 0710 left the avoided trigger of the proc
judge unbuilt: the judge reads one trial label, and 680497 also rolls on the caster's own auto attacks, which the
avoided setup of ADR 0709 uses to engage the striker. Owner O-33, mentor D-311 and D-315 (group G5).

## Options

- A proc trigger `avoided` whose trials are the dodged and parried swings, summed by the existing `readings` labels
  and the baseline `added_trials`, with the engage before the learn and asserted guards against a second source.
- Count the caster's own landed auto attacks as further trials of 680497: it judges both sources at one rate and
  cannot tell which one is wrong.
- Evasion (ADR 0709) instead of a forced avoidance: swings then land, and a landed hit is a direct hit that also
  rolls 705534.

## Decision

The `avoided` trigger in its own module (`proc_avoided.py`), with `compare` unchanged. Dodge and parry are forced
to a sum of 100% before every engage and every swing interval, so no swing lands. The guards (own auto attacks,
landed and fully blocked swings since the engage equal 0) are asserts placed before the reads: a breach fails the
part, which is then unmeasured, never judged. Up to ten strikers raise the trial rate (D-315) without weakening the
rule, and optional `striker_auras` carry a root and haste: the first pair attempt (run 20261116-180506) failed the
landed guard in 11 of 26 parts, and a diagnostic read per striker showed whole strikers landing almost every swing
(behind the caster, where a player neither dodges nor parries, `Unit.cpp:3394, 3430`) while others landed none;
Self Root Forever 42716 keeps them in front (the Templar ADR 0161 precedent) and Molten 62531 plus Enrage 2116852
make them swing four times as often. Sizing: 680497 by D-261 (residual 0.001 per pair, min_detectable 4 points: 29,078 trials); 705534 by band
sizing like its counted taken_hit sibling (D-248; D-261 amended by D-315 for rates whose 10% is below the band edge).

## Consequences

- Inert by default: no existing entry uses the action; an avoided entry does not change a sibling's label or key
  (`same_roll` keeps the two apart). Templar 19 and Necromancer 23 digests unmoved; Witch Hunter output changes only
  in the new avoided scenarios and in the passive notes of 680497 and 705534 that name the new entries.
- Seeded tests (`test_proc_avoided.py`): the engage precedes the learn and the guards precede the reads; the
  reading sums both outcomes; faulty triggers are refused. Mutant: a server that procs on dodges only alerts; an
  engage-time proc before the learn alerts.
- The auto attack half of 140.0 is not judged by this entry.
