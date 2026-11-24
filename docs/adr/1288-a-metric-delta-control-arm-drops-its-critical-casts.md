# 1288. A metric delta control arm drops its critical casts

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

Felsworn part 56.0, Doomsayer 520833: "Critical strikes with Sargeron Smite now refund 1 Felfury". Its control entry
`control_no_crit` casts Sargeron Smite 802060 once before and once after a real learn, without a forced critical
strike, and expects no Felfury gain. The class file said the reference caster's critical strike chance was 0. It is
not: the Felfire Adept 560836 verdict on the same fixture reads `spell_done_crit_chance` 1.20828 before its own
change. In the final pair fw-pair4, run R2 read a gain of 1 in that control: a critical cast refunds, as the tooltip
says. The flip analysis `final/flips4/report.md` found no server defect; the arm was a 1.2% coin flip per run.

Mentor ruling D-116 (2026-11-24) approved a judge change: per cast, the control arm drops the casts whose recorded
damage event is critical and judges the others, with a stated minimum of non-critical casts below which the arm is
unmeasured. The entry is sized so the residual unmeasured probability is under 0.1%.

Options considered: voiding the whole arm when its single cast crits (refused by D-116: it only turns the flip from
an alert into an unmeasured one); a crit-suppressing fixture (fixture 984954, Effect[1] aura 57 at -1000% spell crit,
reaches the player spell crit field (StatSystem.cpp:1013, Unit.cpp:10338-10340) and entries 520246 and 806111 already
use it; it was a simpler route, missed when this option was designed, and stays a valid alternative for other entries);
a rate-based correction (refused: the drop
must rest on the recorded event); repeated treatment casts with a per-cast critical read (chosen).

## Decision

- New `metric_delta` option module `uncritical_casts: {"casts": N, "min_uncritical": M}`
  ([doc](../../apps/coa-gameplay-test/conformance/docs/metric_delta_options/uncritical_casts.md)). It repeats the
  treatment cast block N - 1 times with its own reading, and reads after the before reading and after each treatment
  reading the cumulative critical and non-critical `spell_damage_count` of the trigger at the dummy.
- The verdict drops a treatment cast whose critical count rose or that landed no non-critical hit, judges each
  remaining cast with the plain `metric_delta` rule on its own reading, gives the first non-`ok` one, and is
  `unmeasured` below M remaining casts. The judge names no class or spell.
- The option is opt-in and refused outside the plain between-gate shape at the dummy; no evidence row changes (the
  judged metric stays the entry's own).
- Doomsayer 520833 `control_no_crit` takes N = 4, M = 2. At p = 0.0120828 per cast the entry is unmeasured with
  P(at least 3 critical of 4) = 4p^3(1 - p) + p^4 = 6.99e-06 per run, 1.40e-05 per pair. Its observe source no
  longer claims a crit chance of 0.

## Consequences

- A critical control cast can no longer read as a false alert, and a dropped cast cannot become a false `ok`: every
  kept cast must hold the claim on its own.
- The control arm waits three more casts (4.5 s with the entry's 1500 ms wait).
- Finished classes regenerate byte-identical: no other entry sets the option.
- The verdicts of this entry after the change come from focused reruns, not from the pair of record (D-116).
