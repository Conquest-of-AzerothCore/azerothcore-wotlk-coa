# 0202. Refuse a mount cast under an aura, and dismount when it lands

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0194 (a mount set before a mounted-only cast)

## Context

Crusader's Brand 300513, claim 15: "Brand an enemy for $d, preventing them from mounting, ...". Two server paths carry
it: `Spell::CheckCast` refuses a SPELL_AURA_MOUNTED cast while the caster holds 300513 with
SPELL_FAILED_CASTER_AURASTATE (Spell.cpp:6857-6860), and the brand's apply hook removes the mount auras of its target
(AscensionTemplarAuras.cpp:107-112). ADR 0194 mounts the *caster* with `set_aura` before a mounted-only cast; no kind
cast a mount spell or read a mount under another aura. The claim had no label.

## Considered options

1. A `cast_condition` condition for "aura absent". Its gated spell is both learned and judged against the entry's own
   tooltip, so the quote (on 300513) and the attempted spell (the mount) would have to be split, and it has no
   mounted-state reading.
2. `cast_state` with the mount as its control spell. It has no arm without the aura, so a mount that never works at
   the site would pass.
3. A small kind with the mount attempt on both sides of the aura and a dismount reading. Chosen.

## Decision

Kind `mount_block` (`spell`, `name`, `quote`, optional `mount_spell`, default Brown Horse 458, which must apply
SPELL_AURA_MOUNTED). At the outdoor site of `cast_condition`, the caster sets `spell` on itself (so the apply hooks
run), attempts the mount (refused with 22, no mount aura after the cast time), loses `spell`, attempts it again (no
failure, mounted: the control), and gets `spell` again (the mount aura is gone). Labels `<spell> mount_block <mount>
blocked|unmounted|allowed|mounted|dismounted`, check `behaviour_cast_condition`, judged exactly.

## Consequences

- Claim 15 is judged on both server paths; a brand applied by a creature does not run the apply hook (it needs a
  player caster), so the scenario's brand is the caster's own.
- Existing scenarios regenerate byte-identical (1576 of 1576); one new scenario.
- Tests: `test_behaviours.MountBlockScenarioTests`: the five expected codes, the order of teleport, brand and casts, a
  mount that goes through the brand or survives it alerts, a mount spell without a mounted aura is refused.
