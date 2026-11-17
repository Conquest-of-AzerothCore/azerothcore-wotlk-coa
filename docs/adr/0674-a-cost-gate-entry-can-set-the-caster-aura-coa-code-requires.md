# 0674. A cost gate entry can set the caster aura CoA code requires

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0137, ADR 0590

## Context

`cost_gate_scenario` sets only the raw DBC `CasterAuraSpell` before a cast (`required_aura_steps`, values.py). The
Witch Hunter Trap launchers 680376, 681562, 681563 and 681564 have `CasterAuraSpell` 0 in Spell.dbc, but
`ApplyContracts` gives them Trap Launcher 802272 at load (`AscensionWitchHunterCompletion.cpp:114-119`). Every
Trapper 681180 launcher arm was refused with `SPELL_FAILED_CASTER_AURASTATE` (22) before the cooldown test (final04,
12 labels). The class-file `cast_auras` field already says "set these auras before casting this spell", but only
value and hit scenarios read it; applying it to cost gates too would change the Templar's Blade of Faith cost gates.

## Options

- `required_aura_steps` reads the server's corrected CasterAuraSpell: the DBC tooling has no load-time view.
- `cost_gate_scenario` applies the class-file `cast_auras`: changes finished-class scenarios (Templar 803880).
- The same `{spell, auras, reason}` shape on the cost gate entry, opt-in per entry.

## Decision

A cost gate entry's `cast_auras` sets each listed aura on the caster before every cast of that spell in the scenario
(setup, priming, after and attempt casts). Entries without it are unchanged.

## Consequences

- Tests: `CostGateScenarioTests` (cast auras before each of the six launcher casts, none without the field, a
  malformed item refused).
- Templar and Necromancer generations stay byte-identical (no entry sets the field).
- No alerting mutant: the field adds a precondition, not a check; the arms keep their exact judgement.
