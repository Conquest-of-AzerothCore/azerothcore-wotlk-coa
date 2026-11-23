# 0744. A rank hit can skip the target resistance

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 167.1 (Desecrate 681211, "dealing Weapon Damage plus ${$m1+0} as Shadow damage, piercing
resistances") is judged by `681211 hit_mean`. Since the server fix of Witch Hunter ADR 0014 the hit is no longer
partially resisted, and the label alerts in both runs of the desecrate pair (457.27 / 458.05 against a rank model of
402.945, tooltip mean 457.95): `rank_hit` always subtracts the partial resist computed from the dummy's measured
Shadow resistance. The script hit model already has a per-entry `unresisted` read (ADR 0220); the rank hit model has
none. Mentor ruling D-216 (tool item 18).

## Options

- An opt-in class-file list `unresisted_rank_hits`: a listed rank's school hit takes no resistance mitigation.
- Reading SPELL_ATTR5_NO_PARTIAL_RESISTS from the DBC: Necromancer and Felsworn ranks set the same bit, and the
  engine does not read it, so their hits are resisted; the model would stop matching them (D-195).
- Leaving the label at alert: the server matches the tooltip, so the alert is a model defect.

## Decision

The opt-in list. A listed rank keeps every other part of the model (weapon roll, modifiers, rolls); only the partial
resist mitigation is dropped, matching the SPELL_ATTR4_NO_CAST_LOG contract the server fix sets. A listed rank whose
hit school is physical is refused, since armor is not a resistance. The hit rule names the skipped resistance.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); neither class
  file holds the list.
- Seeded tests: unlisted, Desecrate's model subtracts the resistance of a 5000 Shadow resistance dummy and of the
  reference target; listed, the model equals the tooltip mean at any resistance; a listed physical rank (Stake 681350)
  is refused; only a listed hit's rule names the skipped resistance; the finished class files hold no list.
- Witch Hunter: `unresisted_rank_hits: [681211]`; reference model 457.5 against the tooltip mean 457.95.
