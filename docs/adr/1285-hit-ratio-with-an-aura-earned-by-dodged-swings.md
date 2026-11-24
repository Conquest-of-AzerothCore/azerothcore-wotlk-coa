# 1285. Hit ratio with an aura earned by dodged swings

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-24
- Builds on: ADR 0782 (`versus_creature_type`, a hit_ratio option module), the `proc_avoided` strikers

## Context

Vengeance Is Mine 804822: "Dodging or parrying an attack now gives you a $h% chance to make your next 10 instances of
damage with Twin Slice deal $807163s1% increased damage". The hit_ratio entry `twin_slice_damage` measures the +30%
with 807163 put by the harness (`set_aura`), which mentor ruling Felsworn D-67 does not count without a real route.
`avoided_proc_instances` earns 807163 for real but reads hit counts and Felfury only. Mentor ruling Felsworn D-109 (2)
refused a new evidence row for `aura_amount` and asked for a second real design: repeat the real dodge grant over many
trials and pool the plain hits made under the proc against the same count without it, sized from the measured spread,
judged by the existing band (controller, 2026-11-24: no tolerance change).

## Options

- Read `aura_amount` of the earned aura as the D-67 equivalence arm. Refused (D-109): `aura_amount` stays a readback.
- Extend `avoided_proc_instances` with a damage ratio. Not chosen: a second ratio judge beside hit_ratio's.
- An opt-in hit_ratio option that earns the treatment aura by dodged swings before every trial. Chosen: the hit_ratio
  judge, interval, band and parts stay unchanged.

## Decision

`avoided_grant` (`hit_ratio_avoided.py`): `{"proc_aura", "striker_entry", "strikers", "striker_auras", "swing_ms",
"grant_ms", "lead_ms"}`. The `proc_avoided` strikers engage the caster before the arms; in both arms, before every
observed cast, they swing for `grant_ms` (plus `lead_ms` before the first trial of each arm, so the learn stays the only
difference between the arms) with the caster's dodge at 100% and parry at 0, and `proc_aura` is read on the caster. The
passive is learned in the treatment arm only; an arm that sets `proc_aura`, a shared learn, swings, versus, a target
health, a rate or a target other than the first striker are refused at generation. The judge voids the run
(`unmeasured`) when a treatment trial reads `proc_aura` absent, a control trial reads it present, or a read is
missing; otherwise hit_ratio judges the pooled plain hits as before. No metric, evidence class, tolerance or closing
key changes.

## Consequences

- An entry without the field generates byte-identical scenarios; finished classes 15, 19, 19 `--stack`, 23 and 27
  regenerate byte-identical.
- Seeded tests in `test_hit_ratio_avoided.py`: a run holding the aura exactly in the treatment is judged as without the
  option; an absent treatment read, a present control read and a missing read void it; a +14% mutant still alerts;
  malformed options and a set, shared or misdirected grant are refused; the scenario reads the aura before every cast
  and never sets it.
- Felsworn: `804822 behaviour_hit_ratio twin_slice_damage_earned`, 13 parts of 52 trials per arm (676; one scenario
  holds 52). A first pair at 10 parts of 53 read a 99% half-width of 1.01 points (542 trials per arm needed for 1
  point, half the 2-point band) and, with a 1500 ms window only, one void: 1 of 20 first treatment trials read the aura
  absent, 0 of 1040 later trials. `lead_ms` 6000 was added (controller, 2026-11-24: fixture and sizing, not a judge
  change); the residual void chance per part, about 3e-7 if the no-proc chance falls geometrically with the window, is
  an estimate from that one count.
