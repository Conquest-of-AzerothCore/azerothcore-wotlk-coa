# 0734. A metric delta hit can hold attack power and record its spell power

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 51.0 (Torchlight 503662, "${$m2+$AP*0.3+$spfi*0.45} Fire damage") is refused by the D-57 rule
(ADR 0686): its `spell_bonus_data` row has a spell power coefficient, so it needs a passing hit at a recorded non-zero
spell power, and no hit judge records one. `player_spell_power` sets a spell power fixture but records nothing, and no
option sets attack power, so the attack power and spell power terms of one hit could not be judged apart. Gap design
H2 (c13 gap designs), mentor ruling D-201.

## Options

- A `player_attack_power` option (the harness `attack_power` player fixture), and an opt-in `hit_arm` form of
  `player_spell_power` that reads the caster's spell power before the judged reading and records it on the verdict.
- Recording the fixture amount for every `player_spell_power` entry: it would change the finished classes' models.
- A `hit_ratio` arm with a spell power aura: `hit_ratio` records no spell power either.

## Decision

The two options. The spell power is the run's own read of the trigger's first magic school, not the fixture amount;
only a positive read is recorded. A `hit_arm` entry judges the caster's `spell_damage_total` or `spell_heal_total`.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`); the integer form
  of `player_spell_power` is unchanged.
- Seeded tests: the attack power fixture is set and refused unless positive; the spell power read sits right before
  the judged reading; a conformant verdict records a positive read, and a zero or missing read records nothing (the
  mutant that records any read would let `bonus_terms_unproven` pass a hit at no spell power); a plain integer reads
  and records nothing; a hit arm needs a hit metric and a positive amount.
- Witch Hunter: `503662 behaviour_metric_delta torch_ap` and `torch_sp`, one forced critical Torchlight each, judged in
  the narrow range of the doubled $m2 plus the attack power or the spell power term.
