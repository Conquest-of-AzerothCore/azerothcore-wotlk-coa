# 0735. A metric delta strike can be avoided as set

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 50.0 (Dark Riposte 503659, "Parrying enemy attacks now restores $504475s1% of your missing health
and Rage.") needs a parried strike: the server heals and energizes 5% of the missing health and Rage when an incoming
hit is parried (`AscensionWitchHunterEvents.cpp:158-159, 313-319`). A `metric_delta` strike lands, misses, or is
avoided at the caster's own chances, so the parry was not forced (c12-bk). Gap design H4 (c13 gap designs), mentor
ruling D-201.

## Options

- A `metric_delta` option that sets the caster's dodge and parry with the existing `set_combat_avoidance` step right
  before each striker cast.
- A dodge or parry aura through `phase_auras`: its percent adds to the caster's own chance, so the outcome is not
  certain.

## Decision

The option. It adds steps only; the strike is a melee-class spell (Strike 11976), which the combat table can parry.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the avoidance is set right before each of the 16 strikes; none without the option; an entry without a
  strike, an empty or out-of-range avoidance, or another field is refused. It adds no check, so there is no mutant.
- Witch Hunter: no use. The pilot (run 20261116-061937) parried Strike 11976 at 100% and Dark Riposte healed nothing
  in either phase: a parried spell deals no damage, so its proc event carries `PROC_SPELL_TYPE_NO_DMG_HEAL`
  (`Unit.cpp:7650-7657`), and the 503659 `spell_proc` row asks `SpellTypeMask` 1 (damage) of spell procs
  (`SpellMgr.cpp:966-971`; `rev_20260908_07_witch_hunter_completion.sql:19`). Only a parried melee auto-attack, which
  that mask does not filter, can trigger it. Claim 50.0 needs a single parried striker swing, which no step makes
  (the harness `attack` step is player-only): a design line for the mentor.
