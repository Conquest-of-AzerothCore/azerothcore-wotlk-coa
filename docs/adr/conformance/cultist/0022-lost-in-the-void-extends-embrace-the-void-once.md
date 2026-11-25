# 0022. Lost in the Void extends Embrace the Void once

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-25

## Context

Lost in the Void 704881 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Increases the duration of
Embrace the Void by `$/1000;s3` sec and it now heals you for an additional `$s1%` of the damage taken while active and
its cooldown is reduced by `$/1000;s2` sec." Embrace the Void 582591 has `DurationIndex = 32` (6000 ms) and
`SpellFamilyFlags[0] = 33554432` (`0x2000000`). `704881 Effect[2]` gives `$s3 = 4` s (`BasePoints = 3999`, `DieSides =
1`), so the expected duration with Lost in the Void is `6000 + 4000 = 10000 ms` (10 s).

Two paths added `+4000 ms` each to 582591:

- Native path: `704881 Effect[2]` is aura 107 `SPELL_AURA_ADD_FLAT_MODIFIER`, `MiscValue = 1` (`SPELLMOD_DURATION`),
  `+4000 ms`, `EffectSpellClassMask[6] = 33554432` (matching 582591). `Aura::CalcMaxDuration`
  (`src/server/game/Spells/Auras/SpellAuras.cpp:829`) applies this modifier via `ApplySpellMod`.
- Class path: `cultist_spells::OnCalcMaxDuration` (`src/server/coa/AscensionCultistAbilities.cpp:114-115`, since
  initial commit `e36bc50aad`, no rationale given) ran at `SpellAuras.cpp:825` before `ApplySpellMod` and executed
  `if (Named(aura->GetSpellInfo(), 582591) && player->HasAura(704881)) duration += std::abs(Amount(704881, 2));`,
  adding a second `+4000 ms` for a total duration of 14000 ms.

Conformance pair `cu-g8c` `prove-p3` (`20261125-002444` / `20261125-002520`, build `b6e563ae7771`, `Spell.dbc`
`4e4ed9ba`) measured `704881 duration_expiry` with aura 582591 present (`1`) at `9209 ms` (window `9100..9600 ms`, as
expected) and still present (`1`) at `10818 ms` (window `10400..10900 ms`, expected `0`) in both runs.

## Options

- Delete `AscensionCultistAbilities.cpp:114-115` and let the native `SPELLMOD_DURATION` modifier on `704881 Effect[2]`
  add the single `+4000 ms`.
- Neutralize `704881 Effect[2]` in `AscensionCultistContracts.cpp` and keep the `OnCalcMaxDuration` hook. Rejected:
  the native `SPELLMOD_DURATION` path already applies cleanly without class hook code.

## Decision

Delete the 582591 / 704881 branch in `cultist_spells::OnCalcMaxDuration`
(`src/server/coa/AscensionCultistAbilities.cpp`). No shared engine file, DBC, SQL, or client text changes.

## Consequences

- Embrace the Void 582591 lasts 6 s without Lost in the Void and 10 s with Lost in the Void 704881.
- No other spell is reached: the deleted branch was keyed strictly to `Named(aura->GetSpellInfo(), 582591) &&
  player->HasAura(704881)`; the Herald (`807128`) branch in `OnCalcMaxDuration`, `704881 Effect[0]` (heal bonus), and
  `704881 Effect[1]` (cooldown reduction) are untouched. No existing non-conformance scenario casts 582591 or 704881.
- Regressions (`prove-C`, runs `20261125-052120` and `20261125-052156`, build `87f3a576ecb6`, 14/14 ok, 0 flips,
  `evidence: behaviour` on all 6 clauses): `704881 duration_expiry` (582591 present `1` at 9209 ms, absent `0` at
  10818 ms in both runs), `704881 duration_contrast` (0 -> 1), `704881 heal_bonus` (0.4995 -> 1.0), `704881 cost_gate`
  (67 / 0 / 67), and all 8 `582591` base entries (`survive_control`, `survive_treatment`, `duration` [5509->1 /
  6518->0], `end_heal` [0.4995], `cap_2000_holds`, `cap_1900_breaks`, `cap_3000_holds`, `cap_2850_breaks`) unchanged.
