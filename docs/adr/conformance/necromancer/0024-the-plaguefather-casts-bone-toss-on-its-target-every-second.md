# 0024. The Plaguefather casts Bone Toss on its target every second

- Status: accepted
- Date: 2026-11-13

## Context

Animate: Plaguefather 805048 ("and reducing their attack power by"): no code cast Bone Toss 704706; the Plaguefather
50385 only emitted Zombie Plague on its damage. The owner ruled (Q-a1-8, option a, and the 09:0x go: "toute les
1sec") that the Plaguefather casts Bone Toss 704706 on its current target every 1 s. Fix note FN-own-5, approved by
the mentor (09:3x) with a game-time judge (ADR 0485) and the wait drift inside the band.

## Decision

- `IsSummonedBy` schedules event 10 after 1 s for entry 50385. Event 10, when the owner is not pacified, the
  Plaguefather not controlled and its victim a valid attack target of the owner, casts 704706 at the victim, and
  reschedules itself after 1 s in every case. Event ids 1-9 were taken.

## Consequences

- Regression (class file 805048): `bone_toss` (704706 on the dummy after a commanded Plaguefather, 0 without one) and
  `bone_toss_period`: the Plaguefather's casts of 704706 over 40000 ms of game time after the Command (game-time window
  40000-40500 ms, ADR 0501), against an uncommanded Plaguefather (0). A period inside the G-19 band 950-1050 ms with
  the first cast within one period gives 38 to 43 casts; the live median 1.24 s gives 32, the old code 0. The count
  bounds the period between about 930 and 1066 ms, a little wider than the band, because the first cast's phase is not
  stamped; a judge dividing stamped game time by stamped casts would be tighter (not built).
- The EventMap reschedules from the execution time, so the real period is 1000 ms plus the creature update step.
  704706's range is "Anywhere": a far victim still gets it. Live Bone Toss timing (median 1.24 s) differs; the ruling
  decides.
