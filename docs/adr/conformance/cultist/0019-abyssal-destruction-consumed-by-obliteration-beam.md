# 0019. Owner ruling Q-cu-14: Abyssal Destruction buff is consumed by Obliteration Beam

- Status: accepted (owner ruling Cultist Q-cu-14 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

Abyssal Destruction `300308` -> stacking buff `300605` (server `Spell.dbc`, `Description[enUS]`): "Increases the damage
dealt of your next |cffffffffObliteration Beam|r by $s1%, stacking $u times, for $d." (`$s1 = 5`, `$u = 10`, `$d = 15 sec`,
`Effect[0]` aura `108` `SPELL_AURA_ADD_PCT_MODIFIER` on `EffectSpellClassMask[0] = 131072` matching Obliteration Beam
damage spell `805573`; `ProcFlags = 0`, `ProcCharges = 0`).

Cultist cast-consumed buffs are removed in `cultist_spells::OnSpellCast` via `selected[]`, `Select()`,
`OnSpellBeforeEffects`, and `Finish()` (`src/server/coa/AscensionCultistAbilities.cpp:19-40,78-85,201`). Buff `300605`
was absent from `selected[]` and `Select()`, so casting Obliteration Beam (`805572`..`806897`, linked under `805572` in
`spell_ranks`) left `300605` active for its full 15 s duration.

Before measurement (`batch2/cu-rg6/review.md` check 1, `prove-p2` run 1 & run 2): `300308 behaviour_metric_delta
oblit_consumes` alerted with `aura 300605` reading `0` before and `1` after casting `806897` (against expected `0`).
Archived live combat logs (`ev1.md`) strongly agreed with the tooltip (4 logs, 3 players: 298/299 = 99.7% removed within
0–4 ms of Obliteration Beam).

The owner ruled (Cultist `Q-cu-14` / `O-15`, 2026-11-25): `300605` is consumed by Obliteration Beam.

## Options

- Add `300605` to `selected[]` and `case 300605: return Named(info, 805572);` to `Select()` in
  `src/server/coa/AscensionCultistAbilities.cpp`. Chosen: `Spell::cast` runs `OnSpellBeforeEffects` (`Spell.cpp:4056`)
  -> `HandleLaunchPhase` (`Spell.cpp:4058`, where `EffectTriggerSpell` at `SpellEffects.cpp:1707-1862` immediately casts
  `805573` while `300605` is still active) -> `OnSpellCast` (`Spell.cpp:4203`, calling `Finish()` to remove all stacks of
  `300605` on the root cast while ignoring triggered `805573`).
- Set `ProcCharges = 1` on `300605` in `ApplyContracts`. Rejected: `300605` stacks up to 10 doses on one aura and has
  `ProcFlags = 0`; the existing Cultist `selected[]`/`Finish()` mechanism handles multi-stack single-cast removal cleanly
  without interacting with spell-mod charge logic.

## Decision

In `src/server/coa/AscensionCultistAbilities.cpp`, add `300605` to `selected[]` and `case 300605: return Named(info, 805572);`
to `Select()`. No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- Every rank of Obliteration Beam (`805572`, `807969`, `806893..806897`) receives the full stacked `+5%/stack` bonus on its
  triggered `805573` damage hit and then removes `300605` on cast completion. No other Cultist spell or other class is
  affected.
- Regressions (counted pair `prove-2` `20261125-090640` / `20261125-090726`, build `3732deaa8812`):
  - `300308 behaviour_metric_delta oblit_consumes` (1 stack): `0` / `0` (`ok/ok`, unlearned control `0`).
  - `300308 behaviour_metric_delta oblit_consumes_10stacks` (10 stacks): `0` / `0` (`ok/ok`, unlearned control `0`).
  - `300308 behaviour_metric_delta oblit_damage_1stack`: `31484` / `31484` (`ok/ok`, proves the consuming cast still gets
    `+5%`).
  - `300308 behaviour_metric_delta oblit_damage_10stacks`: `38395` / `38395` (`ok/ok`, proves the consuming cast still gets
    `+50%`).
  - All 8 sibling `300308` checks (`insanity_*`, `cd_cut_*`, `grants_stack`, `stacks_cap`, `duration*`) and existing
    handwritten scenario `cultist-abyssal-destruction-single-reduction` (`20261125-090952`) pass unchanged.
