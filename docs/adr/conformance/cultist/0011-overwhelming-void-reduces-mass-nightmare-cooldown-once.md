# 0011. Overwhelming Void reduces Mass Nightmare's cooldown once

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-25

## Context

Overwhelming Void 707429 (server `Spell.dbc`, `SpellFamilyName` 31, `Description[enUS]`): "Your Mass Nightmare now
triggers a 60 sec reduced cooldown when used at or above 80 Insanity." Mass Nightmare 805114 has `RecoveryTime =
180000 ms` (`SpellFamilyName` 31, `SpellFamilyFlags[0] = 2048`). Expected cooldown: 120 s when cast at `>= 80`
Insanity, 180 s at 79 Insanity.

Two paths subtracted 60 s each when Mass Nightmare was cast at `>= 80` Insanity:

- Native path: `AscensionCultist::Refresh` (`src/server/coa/AscensionCultist.cpp:269-271`) applies marker aura 680604
  ("80 Insanity", `SpellFamilyFlags[0] = 1`) while `stacks >= 80`. In `Spell.dbc`, 680604 `Effect[2]` is aura 107
  `SPELLMOD_COOLDOWN` (`MiscValue = 11`, `BasePoints = -1`, `DieSides = 1`, `EffectSpellClassMask[6] = 2048` matching
  805114), and 707429 `Effect[0]` is aura 107 `SPELLMOD_EFFECT3` (`MiscValue = 23`, `BasePoints = -60001`,
  `DieSides = 1`: `-60000 ms`, `EffectSpellClassMask[0] = 1` matching 680604). Together they reduce 805114's cooldown
  by 60000 ms natively.
- Class path: `cultist_spells::OnSpellCast` (`src/server/coa/AscensionCultistAbilities.cpp:201-202`, since initial
  commit `e36bc50aad`, no rationale given) additionally ran `if (id == 805114 && player->HasAura(707429) &&
  spell->GetScriptValue(Insanity) >= 80) Reduce(player, id, 60000);`, subtracting a second 60000 ms.

As a result, Mass Nightmare's cooldown at 80 Insanity dropped to 60 s. Conformance pair `cu-h1` `prove-batch-a`
(`20261125-005526` / `20261125-005557`, build `ecc43e16424b`, `Spell.dbc` `4e4ed9ba`) measured `707429 at_79` at gain
1 (refused at 121 s, 180 s CD as expected) and `707429 at_80_still_cd` at gain 2 (expected 1: cast at 119 s
succeeded; bracket probes at 59 s refused and 61 s succeeded confirmed 60 s CD).

## Options

- Delete `AscensionCultistAbilities.cpp:201-202` and let the native `707429 -> 680604 Effect[2]` modifier deliver the
  single `-60000 ms` reduction while `stacks >= 80`.
- Neutralize 707429 `Effect[0]` in `AscensionCultistContracts.cpp` and keep the script call. Rejected: the native DBC
  modifier already handles the exact `>= 80` Insanity condition cleanly without extra script code.

## Decision

Delete the duplicate `Reduce(player, id, 60000)` block for 805114 / 707429 in `cultist_spells::OnSpellCast`
(`src/server/coa/AscensionCultistAbilities.cpp`). No shared engine file, DBC, SQL, or client text changes.

## Consequences

- Mass Nightmare 805114 with Overwhelming Void 707429 has a 120 s cooldown at `>= 80` Insanity and keeps its 180 s
  cooldown at 79 Insanity.
- No other spell is reached: the deleted branch was keyed strictly to `id == 805114 && player->HasAura(707429)`, and
  680604 and 707429 DBC effects are untouched.
- Existing scenarios and conformance checks for Mass Nightmare 805114 stayed unchanged (`prove-B`, runs
  `20261125-051823` and `20261125-051857`, build `840e105e4f8f`, 6/6 ok, 0 flips: `805114 targets`,
  `horrify_duration`, and `lockout` all ok; `apps/coa-gameplay-test/scenarios/coa-talent-learning-cue-4334.json`
  passed in `20261125-051924`).
- Regressions (`prove-B`, `20261125-051823` / `20261125-051857`, build `840e105e4f8f`, `evidence: behaviour`):
  `707429 behaviour_metric_delta at_80_ready` (1 -> 3, gain 2 at 121 s), `at_80_still_cd` (1 -> 2, gain 1 at 119 s),
  and control arm `at_79` (1 -> 2, gain 1 at 121 s).
