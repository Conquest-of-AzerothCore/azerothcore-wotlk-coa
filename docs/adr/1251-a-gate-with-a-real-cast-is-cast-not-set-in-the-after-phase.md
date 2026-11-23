# 1251. A gate with a real cast is cast, not set, in the after phase

- Status: accepted (number provisional, assigned at merge)
- Date: 2026-11-23
- Decided by: controller go 2026-11-23 after review I2 of tool group fw-tg-stack (Felsworn 14, Reckoning 802058
  "stacking $524632u times.")

## Context

The Reckoning 802058 stack-cap entry learned 802058 between the phases and then set its aura on the caster with
`after_auras`. 802058 is an active spell (CastingTimeIndex 1, RecoveryTime 120000 ms, StartRecoveryTime 0): learning
it applies nothing, and the contract named the learn as the cause while a harness fixture supplied the aura. Guide 3.4
asks for the real cast where it costs about the same as a fixture. The existing `gate_cast` casts a gate only between
two `attack_swings` phases.

## Options

- Keep `after_auras` and name the fixture in the contract: the claim's own spell stays a fixture.
- Allow `gate_cast` on cast-fed phases: a built-in field of `metric_delta_scenario` changes for every kind of entry.
- A `metric_delta` option that casts the gate at the caster at the start of the after phase through the existing
  named point `phase_steps`, with the existing `after_start_reads` and `void_on_cast_failure` as its proof.

## Decision

The option `after_gate_cast: true` adds `reset_cooldown` and a `cast` of the gate (`gate_spell`, else `spell`) at the
caster at the start of the after phase, before the feed and trigger casts. It requires `after_start_reads` with the
gate expected present (read right after the cast) and `void_on_cast_failure`, so a cast that did not land or was
refused makes the verdict `unmeasured`. It needs the default gate timing, no attack swings, and the gate not also an
after or phase aura. The contract states the real cast. Python only, opt-in.

## Consequences

- Test: `AfterGateCastTests` (metric_delta_options/test_after_gate_cast.py): the cast's place, an entry without the
  option unchanged, a landed cast judged, a cast that did not land (aura absent or unread) and a refused cast
  `unmeasured`, refused inputs.
- Only entries that set the option change; finished-class scenario digests are unchanged.
- An instant gate with a global cooldown would delay the first feed cast; the entry then needs a wait or a gate
  without one (802058 has StartRecoveryTime 0).
- Documented in `apps/coa-gameplay-test/conformance/docs/metric_delta_options/after_gate_cast.md`.
