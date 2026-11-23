# 0033. Mojo Beam's drain does not scale with its branches

- Status: accepted (contributor decision 2026-11-23); needs further investigation
- Date: 2026-11-23

## Context

Mojo Beam 500950-501118 and 572577: "For every sprouted the branch, you consume more and more mana." The tooltip and
the data give no amount (ManaCostPercentage 15 on cast, no per-second cost). The 2026-09-09 reconstruction charged
every 500 ms tick `max(1, $m2) x branches x (100 + 10 x (tick - 1)) / 200` (`AscensionWitchDoctorBrewing.cpp`, a
local choice in `docs/coa/witch-doctor-completion.md`), $m2 being the beam's aura 353 points (316 at level 60). A full
beam at level 60 then costs about 20.8k mana in a five-player group and 32.5k at eight branches; at level 45 a group
beam spends 2.7k in 3 s. Reports #12847 ("consumes all mana in 2-3 seconds") and #12654 (drained after one Potion Toss
and two Spirit in a Bottle) describe that. The final11 pair read 555 mana for a lone-ally beam and 729 for a branching
one over 1250 ms (`501117 beam_drain`). With 8 branches, tick 4 costs 1643, more than the 1497 mana the regression
refills every 250 ms, so the channel stops (reproduced 20261123-004420).

The contributor's live combat log of 2026-08-31 (aggregates, no power fields) shows one raid Witch Doctor, about 10k
maximum mana (Replenishment 1257670 ticks of a median 487 at 5%), channelling 25 of 32 beams past 8 targets for a
median 7.95 s, with a median of 2 potions inside each beam and beams about 18 s apart; four full 15-16 target beams
fell inside 67 s. That leaves at most about 2k to 7k mana per full beam. The official changelog (#70673, 2026-08-11)
says only that the channel cost "has been increased, and continues to increase the longer you channel".

## Decision

- A tick costs `max(1, $m2) x (100 + 10 x (tick - 1)) / 200` whatever the branch count: the cost still rises over
  the channel, and a full beam costs 14 x $m2 plus its cast (4648 at level 60), inside the live bound.
- The tooltip's "for every sprouted branch" wording is not followed. The live formula is unknown; revisit this when
  a capture with power values exists.

## Consequences

- `501117 beam_drain` now requires the lone-ally and the branching beam to spend the same mana (ADR 1181).
- The potion surcharge 573288 keeps the whole channel (contributor decision 3A, 2026-11-23), as the tooltip says.
