# 1334. Optional `blocked_reason` on `caster_aura_gate`

- Status: accepted
- Date: 2026-11-27

## Context

`kinds/caster_aura_gate.py` checks that a spell carrying a DBC `CasterAuraSpell` is refused when that aura is absent
and accepted when it is present. Previously the blocked-cast expectation was hardcoded to
`SPELL_FAILED_CASTER_AURASTATE` (`22`). Spells whose `OnSpellCheckCast` hook rejects the missing custom resource aura
earlier with `SPELL_FAILED_NO_POWER` (`85`) — such as Felsworn's *Inner Demon* (`804216`, `AscensionFelswornAbilities.cpp:99-100`) —
legitimately return `85` instead of `22` when cast with 0 stacks of `800058` (*Felfury*).

## Decision

Add an optional integer field `blocked_reason` to `caster_aura_gate` (default `SPELL_FAILED_CASTER_AURASTATE = 22`,
validated as a positive `int`). When omitted, existing scenarios and snapshots are unchanged.

## Consequences

- Existing `caster_aura_gate` scenarios keep byte-identical output and expectations.
- *Inner Demon* (`804216`) verifies both refusal (`85` at 0 Felfury) and acceptance (`0` at 1 Felfury) cleanly.
