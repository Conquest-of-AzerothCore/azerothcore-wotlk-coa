# 0022. Owner ruling Q-cu-18: Horrific Revelations grants 5 Insanity per tick

- Status: accepted (owner ruling Cultist Q-cu-18 / O-15, 2026-11-25; provisional number)
- Date: 2026-11-25

## Context

Horrific Revelations `524877` (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Every 1 sec while
Hand of Yogg-Saron is active, you now trigger a Horrific Revelation on the target and generate 5 Insanity."
Hand of Yogg-Saron `704476` (`Description[enUS]` conditional `$?s524877[...][]`): "Every `$t1` sec while active, you
trigger a Horrific Revelation on the target and generate 5 Insanity."

Effective `Spell.dbc` and `pending_db_world` data:

- `704476` (`DurationIndex 8` = `15000 ms`, `EffectAmplitude[0] = 15000` reduced `-14000` to `1000 ms` by `524877`):
  all three effects carry `EffectImplicitTargetA = 21` (`TARGET_UNIT_TARGET_ALLY`) and
  `EffectImplicitTargetB = 1` (`TARGET_UNIT_CASTER`). No `pending_db_world` SQL overrides `704476` targets.
- `ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:208-212`, since initial commit `e36bc50aad`)
  rewrote `704476` `Effects[0]` to `SPELL_AURA_PERIODIC_DUMMY` and cleared `TriggerSpell`, leaving
  `Effects[0].TargetB = TARGET_UNIT_CASTER` intact.
- Casting `704476` on an ally therefore applied `Effects[0]` to both the ally and the caster. Every `1000 ms`,
  `aura_ascension_cultist_lifecycle::Tick` (`src/server/coa/AscensionCultistAuras.cpp:220-224`) ran on both aura
  instances, calling `Resource(player, Insanity, 5)` twice (`+10` Insanity per tick) and also triggering `704473` on
  both units.

Before measurements:

- `524877 behaviour_metric_delta trigger_and_insanity` (`cu-g8c/prove-p3`, `cu-rg8/review.md:109`): ally `704473`
  `0 -> 1`, caster `500706` Insanity `0 -> 10` at `1500 ms` against expected `5` (alert/alert).
- `704476 behaviour_metric_delta with_524877_insanity` (`cu-t10/prove-e1`, build `a863401cd7ce`,
  `cu-rt10/review.md:128`): ally `704473` `0 -> 1`, caster `500706` Insanity `0 -> 10` at `1500 ms` against expected
  `5` (alert/alert).

Live evidence note (`ev1.md:181-203`): a single-player archived combat-log hint (`Jimjonescult`, 2 logs `165` and `168`,
`13/13` non-capped ticks stepping `+10`, `0` stepping `+5`) pointed toward `+10` Insanity per tick. In O-15
(`Q-cu-18`, 2026-11-25), the project owner explicitly chose the tooltip value of `5` Insanity per trigger.

## Options

- Clear `Effects[0].TargetB` on `704476` in `ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`). Chosen:
  `Effects[1]` (`-15%` damage taken) and `Effects[2]` (`+15%` damage done) remain on both ally and caster, while
  `Effects[0]` is placed only on the tethered target, granting `5` Insanity per tick and casting `704473` on the target
  only, and stopping cleanly if the target dies or has `704476` dispelled.
- Guard `GetTarget() != player` inside `aura_ascension_cultist_lifecycle::Tick` (`AscensionCultistAuras.cpp`).
  Rejected: although `704476` carries `AttributesEx = SPELL_ATTR1_EXCLUDE_CASTER` (`SpellInfo.cpp:2000` rejects manual
  self-cast with `SPELL_FAILED_BAD_TARGETS`), keeping `Effects[0]` on the caster leaves a redundant periodic aura
  running on the caster even after the tethered ally dies or is dispelled; clearing `Effects[0].TargetB` eliminates
  the duplicate periodic aura at the contract layer.
- Keep `+10` Insanity per tick and edit the tooltip. Rejected by owner ruling `Q-cu-18`.

## Decision

In `ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), clear `info->Effects[0].TargetB` for `id ==
704476`. No shared engine, DBC, SQL, or client text changes.

## Consequences

- While Hand of Yogg-Saron `704476` is active with Horrific Revelations `524877`, each 1 s tick triggers one Horrific
  Revelation `704473` on the target and generates `5` Insanity.
- No other spell is reached (`id == 704476` only). Existing `704476` damage dealt (`+15%`), damage taken (`-15%`),
  duration (`15 s`), and period checks remain unchanged.
- Regressions (`prove-A`, runs `20261125-085812` and `20261125-090003`, build `a57e6319086f`, `13/15` ok, `0` flips;
  the 2 remaining alerts are pre-existing Q-cu-19 `524877 heal_base` / `heal_sp` outside this item's scope):
  - `524877 behaviour_metric_delta trigger_and_insanity`: `ok` / `ok` (`0 -> 5` Insanity, ally `704473` `0 -> 1`,
    unlearned control `0`).
  - `704476 behaviour_metric_delta with_524877_insanity`: `ok` / `ok` (`0 -> 5` Insanity, ally `704473` `0 -> 1`,
    unlearned control `0`).
  - All 11 sibling entries (`524877 period_early`, `period_late`, `crit_buff`, `max_stacks`, `duration`; `704476
    duration`, `ally_damage_dealt`, `ally_damage_taken`, `without_524877`, `with_524877_period_early`,
    `with_524877_period_late`): `ok` / `ok` with no reading shift.
