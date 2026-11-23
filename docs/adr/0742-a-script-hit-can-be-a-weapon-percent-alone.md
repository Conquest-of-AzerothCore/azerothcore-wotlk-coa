# 0742. A script hit can be a weapon percent alone

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 151.0 (Secret of Raven Hill 680513: Surging Blade 681788 "Slash an enemy for $s1% Weapon Damage")
has no hit label: `script_hit` models a script-cast weapon part only beside a school damage effect
(`script_weapon_part`), and Surging Blade's only damage effect is a 280% weapon percent. Design D-16 (approved for
151.0 in cycle 10, not built) accepts a weapon-percent-only hit, gated to entries without flat terms. Gap design H8
depends on it (mentor ruling D-201: build the dependency first).

## Options

- An opt-in `weapon_only` on `script_hit`: the hit is modelled as the weapon part alone (`expected_hit` on the weapon
  effect's reading, the weapon attacker's attack power, armor mitigation), recorded in the model so the judge uses
  the same model.
- Dropping the school damage requirement for every script hit: an unmodelled entry of a finished class would become
  judged.

## Decision

`weapon_only`, which refuses a hit spell with a school damage effect, more than the one weapon percent effect, a
`value_spell` or `unresisted`.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: Surging Blade is a `weapon` hit showing `$s1` with the flag and unmodelled without it; the mutant that
  sets the flag on a hit with a school part (Dark Peril 685020) is refused; a non-boolean flag is refused.
- Witch Hunter: `680513 script_hit 681788 surging_damage`. Pilot 20261116-065502: 30 usable hits, 368.77 against the
  model 369.27, ok; the control arm counted no hit (30 refused casts without 680513).
- Observation (not changed): Reg's Test Aura 984954, the class files' crit-removal fixture, removes spell crit (its
  Effect[1], -1001%) but raises weapon crit by 101% (its Effect[0], aura 52); the first pilot (20261116-065338)
  under it read 30 of 30 Surging Blades critical. An entry that uses it for a weapon hit reads no non-critical hit.
