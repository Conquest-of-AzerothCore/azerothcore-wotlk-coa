# 0641. A script hit may hold auras on its dummy receiver

- Status: accepted
- Date: 2026-11-13

## Context

Necromancer claim 101.2, Animate: Bone Construct 531130: "deals ... Shadow damage, piercing all invulnerabilities,
resistances, and immunities." Bone Deconstruct 531132 is cast from the Construct at its melee target
(AscensionNecromancerEvents.cpp:180-181); it carries SPELL_ATTR0_NO_IMMUNITIES in the DBC and SPELL_ATTR4_NO_CAST_LOG
from its contract (AscensionNecromancerContracts.cpp:408-409), which skips the resist roll (Unit::CalcAbsorbResist).
The `script_hit` kind measures that hit with its trial plan, control arm and model, but it held auras only on the
caster, so no entry could place an immunity on the dummy the Construct strikes.

## Options

- A metric_delta with dummy phase auras: its setup casts set the DBC cost (300) and not the 1000 Runic Power the
  Construct entries need, and it reads one count against an exact value.
- A new kind for one claim: duplicates the script_hit trials and its hit model.
- An optional `receiver_auras` list on `script_hit`, with `receiver_auras_after_casts` for an aura gained once the
  casts are made.

## Decision

`receiver_auras` (behaviours.py, `script_hit`): `[spell, stacks]` pairs set on the dummy receiver (`set_aura`
`target: dummy`) in every trial of both arms, before the casts, or after them with `receiver_auras_after_casts`;
removed at the end. Refused for another receiver, an empty stack or a timing without auras. Entries without the
field generate unchanged; Templar `generate --class 19` and `--stack` are byte-identical.

## Consequences

- An immunity or an invulnerability on the struck target can be held while a minion's scripted hit is read; the
  control arm (no minion) still counts no hit.
- Seeded tests in test_behaviours.py: the auras precede the casts of every trial or follow them, one removal, none
  without the field, malformed timings refused.
