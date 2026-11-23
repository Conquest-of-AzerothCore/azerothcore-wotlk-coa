# 0694. A caster aura gate is attempted without and with its aura

- Status: proposed
- Date: 2026-11-15

## Context

Quickdraw 806851: "Only usable after critically striking with an ability." Its DBC CasterAuraSpell is 680244, which
the Quickdraw passive 681181 casts on the caster after a direct, non-auto-attack critical hit when the player
`HasSpell(804193)` (AscensionWitchHunterEvents.cpp:128-132, 233-235). The `cast_gate` kind needs a TargetAuraState
and adds the required caster aura to every attempt (`required_aura_steps`), so it cannot show the refusal.
`cast_state` checks the opposite polarity and `mount_block` is mount-specific.

## Options

- Extend `cast_gate` in the shared core with a caster-aura mode.
- A kind module (ADR 0581) that reuses the `behaviour_cast_gate` check, its generic exact judge and its evidence row.

## Decision

The kind `caster_aura_gate` attempts the spell without its CasterAuraSpell (expected 22,
SPELL_FAILED_CASTER_AURASTATE) and with it set by the harness (expected 0). An optional earned arm learns
`earned_learn`, removes the aura, casts `crit_ability` with a forced crit, reads the aura (expected 1) and attempts
again with no fixture (expected 0). The same crit is made first with only the gated spell and the crit ability
learned; its aura read and the `knows_spell` reads of `known_probes` are recorded, not judged. The auto-attack
negative arm of the design is not built: a ranged auto attack has no harness action.

## Consequences

- Tests: `CasterAuraGateTests` (kinds/test_caster_aura_gate.py); page `docs/kinds/caster_aura_gate.md`.
- Entry: Quickdraw 806851 with Darkslayer 804179 and 804193; labels `806851 behaviour_cast_gate
  caster_aura_blocked`, `caster_aura_allowed`, `crit_aura` and `crit_allowed`.
- `behaviour_kinds()` gains `caster_aura_gate` at ORDER 45; the finished classes' scenarios are unchanged.
- Number provisional: shared ADRs are numbered at merge.
