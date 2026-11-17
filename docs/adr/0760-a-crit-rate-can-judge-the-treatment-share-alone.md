# 0760. A crit rate can judge the treatment share alone

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 125.0 (Deal With The Devil 680255, "In addition, your Quickdraw is now guaranteed to critically
strike.") states a share, not a difference: the treatment share is 100% and the control share (the caster's own
ranged crit) is not stated. The `crit_rate` judge compares the difference of the shares with `expected` points, so
it cannot express the claim. The server sets the chance to 100 for a Quickdraw of a caster with the 680255 aura
(`AscensionWitchHunterAbilities.cpp:121-127`). Design P1 of c14-tool2; mentor D-240 and D-244.

## Options

- `treatment_share`: judge the treatment's 99% Wilson lower bound against the stated share minus the G-19 band,
  with the control's upper bound under it as the contrast.
- A `metric_delta` with a forced crit: forces the very outcome the claim states.
- A difference judge with a guessed control share: the control share is not stated.

## Decision

`crit_rate` takes `treatment_share` (equal to `expected`, in (0, 100]): ok when the treatment's lower bound reaches
the floor and the control's upper bound lies under the treatment's lower bound; alert when the treatment's upper
bound lies under the floor; `measured` otherwise. With it, three opt-in fields: an arm's `learn` (learned at the arm's
start and unlearned at its end, `knows_spell` read for every arm-learned spell at each arm's start; a read that
disagrees leaves the verdict unmeasured), the entry's `cast_power` and a stated `dummy_distance`.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the share passes at 160 of 160 against 40 of 160; a short treatment is `measured`; a control at the
  treatment's share is `measured` (no contrast); a wrong `knows_spell` read is unmeasured. Mutant that must alert: a
  treatment share of 40 or 140 in 160.
- Witch Hunter: 680255 `guaranteed_crit`, 160 Quickdraws 806851 per arm (lower bound 96.0% at 160 of 160), 680255
  learned in the treatment only, power 165 = ManaCost 150 x 1.10 (680255 Effect[1] aura 72, 10%; SpellInfo.cpp:3253),
  the dummy at 17.5 yd. Deterministic in the treatment arm.
