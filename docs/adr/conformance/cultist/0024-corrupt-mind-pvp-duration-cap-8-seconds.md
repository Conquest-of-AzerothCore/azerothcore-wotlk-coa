# 0024. Owner ruling Q-cu-28: Corrupt Mind caps PvP duration at 8 seconds

- Status: accepted (owner ruling Cultist Q-cu-28 / O-15, 2026-11-25; provisional number)
- Date: 2026-11-25

## Context

Corrupt Mind `560109` (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Corrupt the mind of an enemy
and spread madness, fearing them in place for `$d` (8 sec vs players), bouncing to up to 2 nearby enemies..."

Effective `Spell.dbc` and `pending_db_world` data:

- `560109`: `DurationIndex 64` (`40000 ms`), `CastingTimeIndex 16` (`1500 ms`), `Speed = 23.0`, `Mechanic = 5`
  (`MECHANIC_FEAR`, `DIMINISHING_FEAR`), `EffectChainTarget = 3`, `MaxAffectedTargets = 3`. No `pending_db_world` SQL
  overrides `560109` duration.
- `GetDiminishingReturnsLimitDuration` (`src/server/game/Spells/SpellMgr.cpp:342-415`) returns `10 * IN_MILLISECONDS`
  for `DIMINISHING_FEAR` spells not explicitly listed, so `Unit::ApplyDiminishingToDuration`
  (`src/server/game/Entities/Unit/Unit.cpp:13234-13243`) capped `560109` at `10000 ms` against players instead of
  `8000 ms`.

Before measurement (`cu-t1/prove-g9`, build `ed20e7787648`, server commit `4d4ac0d30a4b`, `cu-rt1/review.md:191`):

- `560109 behaviour_metric_delta player_duration`: enemy player (`race 2`), `aura 560109` read `0` before cast, `1`
  at `9109 ms` (`~7479 ms` post-apply, expected `1`), and `1` at `10118 ms` (`~8488 ms` post-apply, expected `0`) in
  both runs (alert/alert).
- Sibling `560109 behaviour_metric_delta duration` on PvE creature (`Kobold Vermin 6`) passed (`0 -> 1` at `39609 ms`,
  `0` at `42818 ms`, 40 s).

Live evidence (`ev2.md:176-208`): none for PvP duration (`0` player targets in 186 logs; all 24 PvE creature
applications broke early on damage in `0.000-3.240 s`). Archive tooltip video `q742IyqxrV0` (`6:16`) matches
`"for 40 sec (8 sec vs players)"` verbatim. The project owner ruled (`Q-cu-28 cap_8s`, O-15, 2026-11-25) to cap
Corrupt Mind at 8 s vs players.

## Options

- Clamp `560109` max duration to `8000 ms` inside `cultist_spells::OnCalcMaxDuration`
  (`src/server/coa/AscensionCultistAbilities.cpp`) when the target's effective unit (`target->GetOwner() ?
  target->GetOwner() : target`) is a player or a creature with `CREATURE_FLAG_EXTRA_ALL_DIMINISH`. Chosen:
  `Aura::Aura` (`SpellAuras.cpp:364,371`) sets `m_owner` before `CalcMaxDuration` invokes `OnCalcMaxDuration`
  (`SpellAuras.cpp:825`), which runs before `Unit::ApplyDiminishingToDuration` (`Spell.cpp:3258-3266`). Clamping
  to `8000 ms` beforehand passes `8000 <= 10000` through unchanged on DR level 1 and yields exact DR steps
  `8000 / 4000 / 2000 / 0 ms`, keeps PvE targets at `40000 ms`, and requires no edit to shared engine file
  `src/server/game/Spells/SpellMgr.cpp`.
- Add `560109` to `GetDiminishingReturnsLimitDuration` in `src/server/game/Spells/SpellMgr.cpp`. Rejected: touches
  shared engine code outside class-scoped limits.

## Decision

In `cultist_spells::OnCalcMaxDuration` (`src/server/coa/AscensionCultistAbilities.cpp`), clamp `duration` to at most
`8000 ms` for `aura->GetId() == 560109` when the aura owner's effective unit is a player or carries
`CREATURE_FLAG_EXTRA_ALL_DIMINISH`. No shared engine, DBC, SQL, or client text changes.

## Consequences

- Corrupt Mind `560109` lasts `8 s` against players (and `4 s` / `2 s` / immune on subsequent Fear DR steps) while
  keeping its full `40 s` duration against normal PvE creatures.
- Other spells reached: Hour of Twilight `255275` when casting `560109` on enemy players at channel end; no other
  class or Cultist spell is modified. Existing `OnCalcMaxDuration` consumer `807128` (`18/18` ok) and `525049`
  (`10/10` ok) were re-verified unchanged.
- Regressions (`prove-C2`, runs `20261125-090752` and `20261125-090829`, build `7c3f7b3fc0cd`, `35/35` ok, `0` flips):
  - `560109 behaviour_metric_delta player_duration`: `ok` / `ok` (`0` before cast, `1` at `9109 ms`, `0` at `10118 ms`
    on enemy player `race 2`).
  - `560109 behaviour_metric_delta duration`: `ok` / `ok` (`0` before cast, `1` at `39609 ms`, `0` at `42818 ms` on
    PvE creature `Kobold Vermin 6`, 40 s control preserved).
  - All 5 sibling `560109` entries (`insanity_gain`, `bounce_cap`, `mind_rot_branch`, `damage_breaks`, `damage_holds`),
    all 10 `525049` entries, and all 18 `807128` entries: `ok` / `ok`, no reading moved.
- Note on `prove-C` (`20261125-090520` / `20261125-090618`): all 7 `560109` and 18 `807128` entries passed `ok`/`ok`,
  while an unrelated pre-existing flip occurred on `255275 damage_taken` (`9238` vs `9175` in run 1, `9175` `ok` in
  run 2) due to `301988` Apocalyptic Skies portal spawning at `1500 ms` during `wait_ms: 1500` and rolling a
  Gaze of C'thun self-heal.
