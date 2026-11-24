# 1214. Ally arm ally attacks read the ally's own damage

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Blessing of Triumph 804250: "If the ally falls below 35% maximum health they are healed for $680911s3% of their direct
damage dealt for the remaining duration." The heal 681386 is cast by the Sun Cleric at the ally
(AscensionSunClericEvents.cpp, case 680911) from the ally's own direct damage, so the claim needs the ally to deal
damage under a real 804250 cast and a ratio of the caster's heal to the ally's damage. `ally_arm` casts only from the
caster and refuses caster-scoped reads on an ally. Mentor D-199, D-214.

## Options

- `hit_ratio` with the ally as caster: reads one unit's hits only, not the caster's heal against the ally's damage.
- An opt-in `ally_attacks` list on `ally_arm`, reusing its arms and ratios.

## Decision

`ally_attacks: [{spell, power, source}]`: the ally learns each spell and casts it at the dummy after the trigger (at
the phase steps in an uncast before phase), its mana set to `power`, with a 2000 ms settle and an `assert` of its own
`spell_go_count` at the running total. Arms may read caster-scoped totals on `ally` only for those spells. Refused
without the dummy, with `control_wait`, a non-default gate timing or `setup_only_after`.

## Consequences

- Opt-in; the finished classes regenerate byte-identical.
- Seeded tests: the attack steps and proofs in both phases, the read exemption limited to the attack spells, malformed
  options refused, and a ratio mutant (heal 50% instead of the stated 75%) that alerts.
