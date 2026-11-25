# 0027. Owner ruling Q-cu-19: Horrific Revelation follows displayed base heal

- Status: accepted (owner ruling Cultist Q-cu-19 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

From server `Spell.dbc` (`/srv/coa/server-data/dbc`, `Description[enUS]`):
- Horrific Revelation `704473` (embedded in Horrific Revelations `524877` and Hand of Yogg-Saron `704476` via `@s:704473:0@`):
  "Heals a friendly target for ${$m1+0+$SP*0.678496}, scaling with |cffcfa6ffInsanity|r, and increases their critical strike chance by $s2%, stacking $u times, for $d."

In `Spell.dbc`, `704473` has `BaseLevel = 0`, `SpellLevel = 0`, `MaxLevel = 0`, `Effect[0] = 10` (`SPELL_EFFECT_HEAL`), `EffectBasePoints[0] = 143`, `EffectDieSides[0] = 7`, and `EffectRealPointsPerLevel[0] = 2.5`, with no `SkillLineAbility.dbc` row. Because the tooltip formula `${$m1+0+$SP*0.678496}` omits `$ppl1`, the client displays `[144..150]` at 0 Spell Power (`[1500..1508]` at +2000 SP).

When `aura_ascension_cultist_lifecycle::Tick` (`src/server/coa/AscensionCultistAuras.cpp:222`) casts `704473`, `SpellEffectInfo::CalcValue` (`src/server/game/Spells/SpellInfo.cpp:487-498`) adds `int32((60 - 0) * 2.5f) = +150`, turning `[144..150]` into `[294..300]` (`[1650..1657]` at +2000 SP).

Pre-fix conformance runs (`cu-g8d` `prove-fix1` / `cu-g8c` `prove-p3` `20261125-002444` / `20261125-002520`, build `b6e563ae7771`) measured:
- `524877 behaviour_metric_delta heal_base`: `298` / `295` (`299` in `p3`) against `[144..150]` — alert/alert.
- `524877 behaviour_metric_delta heal_sp`: `1651` / `1654` (`1653` in `p3`) against `[1500..1508]` — alert/alert.

The owner ruled (Cultist `Q-cu-19`, `O-15`, 2026-11-25): `tooltip` — align the heal amount on the displayed tooltip.

## Options

- Zero `info->Effects[0].RealPointsPerLevel = 0.0f;` for `id == 704473` in `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), following Felsworn ADR 0006 and Sun Cleric ADR 0044. Chosen.
- Keep `+150` per-level scaling and edit client tooltip text. Rejected by owner ruling `Q-cu-19`.

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:262-263`), set `info->Effects[0].RealPointsPerLevel = 0.0f;` when `id == 704473`. No shared engine, SQL, DBC, or other-class changes.

## Consequences

- Horrific Revelation `704473` heals for `[144..150] + 0.678496 * SP` at level 60, matching the displayed tooltip.
- No other spell or class is reached (`704473` is cast only by `704476` under `524877`).
- Counted pair (`20261125-091454` / `20261125-091529`, build `40aff5bf4cc4`, 0 flips):
  - `524877 behaviour_metric_delta heal_base`: `148` / `149` (control `0`, expected `[144..150]`) — ok/ok.
  - `524877 behaviour_metric_delta heal_sp`: `1505` / `1500` (control `0`, expected `[1500..1508]`) — ok/ok.
  - Sibling checks on `524877` (`period_early`, `period_late`, `crit_buff`, `max_stacks`, `duration`) and `704476` (`duration`, `ally_damage_dealt`, `ally_damage_taken`, `without_524877`, `with_524877_period_early`, `with_524877_period_late`) all passed ok/ok with no movement. (The two pre-existing `Q-cu-18` Insanity alerts `10 vs 5` are separate and owned by another branch.)
