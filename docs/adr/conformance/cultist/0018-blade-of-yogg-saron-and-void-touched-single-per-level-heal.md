# 0018. Owner ruling Q-cu-11: Blade of Yogg-Saron and Void-Touched count per-level healing once

- Status: accepted (owner ruling Cultist Q-cu-11 / O-15, 2026-11-25)
- Date: 2026-11-25

## Context

Two Cultist healing triggers doubled their `Spell.dbc` `RealPointsPerLevel` scaling at level 60:

- **Blade of Yogg-Saron** `524887` (Rank 1, `bp=34+1=35%`) / `525078` (Rank 2, `bp=69+1=70%`), server `Spell.dbc`
  `Description[enUS]`: "Damage dealt by |cffffffffBlade of the Empire|r now heals the lowest health ally for $s1% of the
  damage dealt plus ${($500748m1+$500748ppl1+$BH*0.4+$AP*.1)*0.5}." Auxiliary heal `500748` has `BaseLevel=SpellLevel=13`,
  `MaxLevel=0`, `BasePoints=150`, `DieSides=1`, `RealPointsPerLevel=5.21` (`151 + floor(47 * 5.21) = 395` at level 60,
  halved by `*0.5` with `0.4*BH + 0.1*AP`).
- **Void-Touched** `300286` -> `301982` (`@s:301982:0@`, `aura 283` `+20%/stack` on mask `1048576`), server `Spell.dbc`
  `Description[enUS]`: "When you cast |cffffffffGaze of C'Thun|r, all stacks are consumed to heal all allies affected by
  |cffffffffVoid-Touched|r for ${$301983m1+$301983ppl1+$BH*0.35}, increased based on how many stacks were on them."
  Auxiliary heal `301983` has `BaseLevel=SpellLevel=17`, `MaxLevel=0`, `BasePoints=99`, `DieSides=1`,
  `RealPointsPerLevel=4.75` (`100 + floor(43 * 4.75) = 304` at level 60; `364` at 1 stack, `608` at 5 stacks, `1204` at
  1 stack with `+2000` SP).

Both handlers called `Amount(id, 0, player)` (`src/server/coa/AscensionCultist.cpp:67-71`), which invokes
`SpellEffectInfo::CalcValue(player)` (`src/server/game/Spells/SpellInfo.cpp:479-516`) and adds
`int32(levelDelta * RealPointsPerLevel)` once, and then passed the result to `Copy(player, ally, id, amount)`
(`src/server/coa/AscensionCultist.cpp:95-99`). `Copy()` calls `CastCustomSpell(id, SPELLVALUE_BASE_POINT0, amount, ...)`,
which invokes `SpellEffectInfo::CalcValue(caster, &bp0)` a second time and adds `RealPointsPerLevel` again (unhalved for
`500748`).

Before measurements:
- `524887` / `525078` (`batch2/cu-rg5/review.md` A2, `prove-b2`): `+245` flat excess on all six arms (Rank 1 `heal_base`
  `~592` against expected `347 ± 8`).
- `300286` (`batch2/cu-rg7/review.md` Alert 1, `cu-g7b/prove-final` `20261124-214632` / `20261124-214705`, build
  `5115cdc4966c`): `gaze_consume_base` `609` vs `[364..365]`, `gaze_consume_sp` `1449` vs `[1204..1205]`,
  `gaze_consume_5stacks` `1016` vs `[608..609]`.
- Archived live combat logs (`ev1.md`) strongly agreed with the tooltip on `301983` (9 players, 24 logs, 5,606 heals:
  1-stack medians `333..489`, below the doubled floor `609`).

The owner ruled (Cultist `Q-cu-11` / `O-15`, 2026-11-25): follow the tooltip value (count per-level scaling once).
Sibling question `Q-cu-12` (Void-Touched leaving 1 stack via `MarkVoidTouched` at `AscensionCultistAbilities.cpp:76`)
remains on hold and is left untouched.

## Options

- Clear `Effects[0].RealPointsPerLevel` on `500748` in `ApplyContracts`, compute `500748`'s single per-level contribution
  from `sSpellStore.LookupEntry(500748)` inside `case 524887: case 525078:` before applying `* 0.5f`, and pass `nullptr`
  caster (`Amount(301983, 0)`) in `AscensionCultistAbilities.cpp` so `Copy()` adds `301983`'s `RealPointsPerLevel` once.
  Chosen: keeps shared `Amount()` and `Copy()` unchanged for all other `CultistCopies` spells and applies `* 0.5f` to
  `500748`'s full `($500748m1+$500748ppl1+$BH*0.4+$AP*.1)` sum.
- Change shared `Copy()` or `SpellEffectInfo::CalcValue`. Rejected: would reach every `CultistCopies` spell or shared
  engine code.

## Decision

1. In `src/server/coa/AscensionCultistContracts.cpp` (`ApplyContracts`), set `info->Effects[0].RealPointsPerLevel = 0.0f`
   for `id == 500748`.
2. In `src/server/coa/AscensionCultistEvents.cpp` (`aura_ascension_cultist_event::Proc`, `case 524887: case 525078:`), add
   `sSpellStore.LookupEntry(500748)->EffectRealPointsPerLevel[0]` scaled with the `CalcValue` level clamp once before
   halving `flat *= .5f`.
3. In `src/server/coa/AscensionCultistAbilities.cpp` (`cultist_spells::OnSpellBeforeEffects`), change
   `Amount(301983, 0, player)` to `Amount(301983, 0)`.

No SQL, DBC, shared engine, or other-class files are changed.

## Consequences

- Only `500748` (Blade of Yogg-Saron) and `301983` (Void-Touched Gaze heal) are reached; no other `CultistCopies` spell
  or other class is affected. `MarkVoidTouched` (`Q-cu-12`, on hold) is unchanged.
- Regressions (counted pair `prove-2` `20261125-090640` / `20261125-090726`, build `3732deaa8812`):
  - `524887`: `heal_base` `346` / `352` (`347 ± 8`, `ok/ok`), `heal_sp` `5523` / `5523` (`5523 ± 8`, `ok/ok`), `heal_ap`
    `3310` / `3313` (`3307 ± 8`, `ok/ok`), unlearned control `0` and caster target control `0`.
  - `525078`: `heal_base` `479` / `475` (`479 ± 15`, `ok/ok`), `heal_sp` `6843` / `6843` (`6831 ± 15`, `ok/ok`), `heal_ap`
    `5390` / `5405` (`5399 ± 15`, `ok/ok`), unlearned control `0` and caster target control `0`.
  - `300286`: `gaze_heal_base` `364` / `364` (`[364..365]`, `ok/ok`), `gaze_consume_sp` `1204` / `1204` (`[1204..1205]`,
    `ok/ok`), `gaze_consume_5stacks` `608` / `608` (`[608..609]`, `ok/ok`); `gaze_consume_base` main heal metric reads
    `364` / `364` while its `301982 aura_stacks == 0` ally arm continues alerting at `1` for held `Q-cu-12`.
  - Existing handwritten scenarios `cultist-void-touched-blade-of-yogg-saron-11428`,
    `cultist-void-touched-marks-and-gaze-heals-11428`, and `cultist-void-touched-shadow-pennant-11428` all pass
    (`20261125-090952`).
