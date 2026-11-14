# 0430. An immunity carried by another aura

- Status: accepted
- Date: 2026-11-13

## Context

- Icebound Champion 807813 and Spellbound Champion 807811 are summons. The immunity is not an aura of the cast spell:
  the Champion puts 807812 (mechanic immunity to silence and interrupt) or 808017 (a spell magnet, by contract) on its
  owner as an owner area aura.
- The `immunity` kind read the cast spell's own aura on the subject for its `applied` and `expired` labels, so a summon
  could not be checked. The silence claim and the deflect claim were route pending (B4 side b).

## Decision

- An `immunity` entry may name `aura`, the aura that carries the immunity. Its `applied` and `expired` reads use that
  aura, and a 500 ms settle follows the cast so the summon can apply it. The fixture casts, their `with`, `without`
  and `control` reads, and the expiry wait from the cast spell's duration are unchanged.
- Without `aura`, an entry reads its own spell as before: `generate --class 19` and `--stack` are byte-identical (2460
  and 40 scenarios).

## Consequences

- `ImmunityCarrierAuraTests` (test_behaviours.py) checks that Icebound Champion reads 807812 and that Lich Form reads
  its own 500981. Reading the cast spell for a carrier entry is the mutant that the first test catches.
- Icebound Champion: Silence 15487 from the dummy lands without the Champion, not with it, and lands again after it.
  Spellbound Champion: Fear 12096 from the dummy lands on the caster without the Champion, not with it, and again
  after it. The interrupt immunity and the redirect to the Champion itself are not read by this kind.
