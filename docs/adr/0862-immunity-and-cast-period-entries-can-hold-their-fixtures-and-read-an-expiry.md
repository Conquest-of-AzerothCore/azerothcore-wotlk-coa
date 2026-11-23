# 0862. Immunity and cast period entries can hold their fixtures and read an expiry

- Status: accepted
- Date: 2026-11-16

## Context

Witching Shroud 805770 states "granting immunity to all harmful magic effects" (claim 389.1). Its cast needs the window
aura 805771, and its stealth hides the caster from a creature outside its combat reach: the first run of the `immunity`
entry failed with "Creature cast failed: 12" (SPELL_FAILED_BAD_TARGETS) because the dummy could not see the caster
(`WorldObject::CanDetectStealthOf`: a distance under the combat reach is always seen).

Scent of Magic 706260 states "Critical strikes now apply Scent of Magic for $800528d" (claim 281.1, 15000 ms). The aura
sits on the owned Shadowhound, which the `last_application_expiry` and `aura_expiry` kinds cannot read, and the first
leap (the only early removal, `AscensionWitchHunterSummons.cpp:136`) needs a victim.

## Options

- A new kind for each: a larger change for two reads on existing shapes.
- A harness change for the dummy's sight or the owned aura read: the harness already offers both reads.
- Opt-in fields on the existing kinds (D-293 category A).

## Decision

- `immunity`: `caster_auras` (spell ids set on the subject before the cast attempt) and `dummy_distance` (yd).
- `cast_period` arm entries: `aura_expiry {"expected_ms", "gone_after_ms"}` with `owned_aura`: a second read of the owned
  aura, game time stamped before the trigger, after it and at both reads; the verdict is ok when the aura is present at
  an age of at least `expected_ms` minus the band and gone at an age of at most `expected_ms` plus it, with none in the
  control.

## Consequences

- Tests: `ImmunityScenarioTests` (caster aura and dummy distance only when named) and `AuraExpiryArmTests`
  (kinds/test_cast_period.py), with mutants for an aura 10% early or late, a held control aura and each missing stamp.
- Only entries that set a field change; the Templar and Necromancer digests are unchanged (source stage passed).
