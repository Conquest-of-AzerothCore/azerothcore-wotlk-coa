# 0678. A metric delta can refresh the melee crit field in both phases

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0582

## Context

Secret Society 680514 "Increases your Shadow critical strike chance ... by $s1%" (aura 350, Shadow) is added at use
time by `Unit::SpellDoneCritChance` (`Unit.cpp:10308-10313`) on top of `PLAYER_CRIT_PERCENTAGE` for a melee spell
(`:10279`). The reference character's melee crit field is 0 until something recomputes it; the learn of 680514 does
(`HandleAscensionModCritChance`, `SpellAuraEffects.cpp:4954-4966`). A control arm read 0 and the treatment 10.29:
the withdrawn crit_rate entry read +10.31 against +8, an incorrect test (stale control field). The mentor allowed
the correction only as a new metric_delta option module (D-30).

## Options

- A `hit_ratio` refresh: edits the owner's kind.
- A metric_delta option module reading `melee_crit_chance_refreshed` (it calls `UpdateCritPercentage(BASE_ATTACK)`)
  at the start of both phases.

## Decision

The option module `crit_field_refresh` (`true`): through `phase_steps`, each phase reads
`melee_crit_chance_refreshed` first; `verdict` makes the result `unmeasured` when a refresh read is missing. It needs
the default between-phases learn.

## Consequences

- Test: `CritFieldRefreshTests` (metric_delta_options/test_crit_field_refresh.py): both refreshes before their
  readings, none without the option, a refreshed 2.29 to 10.29 gain `ok`, a stale 0 control `alert` (the mutant),
  a missing refresh `unmeasured`.
- New Witch Hunter entry `Secret Society (Shadow crit chance)`: `spell_done_crit_chance` of Dusk Blade 802258,
  gain 8 within 0.01.
- Templar and Necromancer generations stay byte-identical (no entry sets the option).
