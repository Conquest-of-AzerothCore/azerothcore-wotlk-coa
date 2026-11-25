# 0020. Shadowy Symbiosis doubles critical block chance only above 60 Insanity

- Status: accepted (provisional number, numbered at merge)
- Date: 2026-11-25

## Context

Shadowy Symbiosis 680574 (server `Spell.dbc`, `SpellFamilyName` 31, `SpellFamilyFlags[0]` `0x10000000`,
`Description[enUS]`): "Your successful blocks now have a `$s2%` chance to critically block for twice the normal amount.
This effect is doubled while above 60 Insanity." `$s2` is `Effect[1]` (`BasePoints` 19, `DieSides` 1: 20%). The
tooltip specifies 20% critical block chance at 59 and 60 Insanity and 40% at 61 Insanity (strictly above 60).

Server `Spell.dbc` defines 680574 (`Attributes` 192: `SPELL_ATTR0_PASSIVE | SPELL_ATTR0_DO_NOT_DISPLAY`) with two
`SPELL_EFFECT_APPLY_AURA` effects using aura 253 `SPELL_AURA_MOD_BLOCK_CRIT_CHANCE`, both with `ImplicitTargetA = 0`:

- `Effect[0]`: `BasePoints = -1`, `DieSides = 1` (0%).
- `Effect[1]`: `BasePoints = 19`, `DieSides = 1` (20%).

Two paths combined to add +20% twice:

- `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp:155-158`, since initial commit
  `e36bc50aad`) left `Effect[0]` active (and set `TargetA = TARGET_UNIT_CASTER` on both effects). Because
  `SPELL_EFFECT_APPLY_AURA` carries `EFFECT_IMPLICIT_TARGET_EXPLICIT` (`SpellInfo.cpp:697`), `Effect[0]` still applies
  to the caster even if its `TargetA` is left at 0 (confirmed in `prove-A`, build `e47aaaa61032`, runs
  `20261125-034910` / `20261125-035034`, which still read 40.0 at 60 and 60.0 at 61).
- Marker aura 680603 ("60 Insanity", applied at `>= 60` Insanity in `AscensionCultist.cpp:269-271`) carries `Effect[1]`
  aura 107 `SPELLMOD_EFFECT1` (`BasePoints = 19`, `DieSides = 1`: +20) on `EffectSpellClassMask[3] = 0x10000000`,
  raising 680574 `Effect[0]` from 0 to +20 at 60 Insanity.
- `AscensionCultist::Refresh` (`src/server/coa/AscensionCultist.cpp:289`) independently doubles `Effect[1]` to 40 when
  `stacks > 60`.

As a result, `Unit::GetTotalAuraModifier(SPELL_AURA_MOD_BLOCK_CRIT_CHANCE)` summed `Effect[0]` and `Effect[1]` to 40%
at 60 Insanity and 60% at 61 Insanity. Conformance pair `cu-h2` `prove-b3` (`20261125-013923` / `20261125-013956`,
build `b21ec720e824`, `Spell.dbc` `4e4ed9ba`) measured `critical_block_chance` at 20.0 at 0 Insanity, 40.0 at 60
(expected 20.0), and 60.0 at 61 (expected 40.0) in both runs.

## Options

- Clear `Effect[0]` (`info->Effects[0].Effect = 0`) and set `Effect[1].TargetA = TARGET_UNIT_CASTER` on 680574 in
  `AscensionCultist::ApplyContracts`. Only `Effect[1]` is instantiated, so 680603's `SPELLMOD_EFFECT1` has no effect
  on 680574, `aura_ascension_cultist_lifecycle::First` (`AscensionCultistAuras.cpp:17-23`) fires on `EFFECT_1`, and
  `AscensionCultist.cpp:289` delivers 20% at `<= 60` and 40% at `> 60`.
- Change 680603 `Effect[1]` or its threshold in `AscensionCultist.cpp:269-271`. Rejected: 680603 is a shared
  threshold marker read by other Cultist spells, and keeping the fix keyed to 680574 avoids side effects.
- Edit `Spell.dbc`. Rejected: shipped DBC files stay untouched and Cultist spell contracts live in
  `AscensionCultistContracts.cpp`.

## Decision

In `AscensionCultist::ApplyContracts` (`src/server/coa/AscensionCultistContracts.cpp`), keyed to spell id 680574,
clear `info->Effects[0].Effect = 0` and set `info->Effects[1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER)`.
No shared engine file, DBC, SQL, or client text changes.

## Consequences

- Shadowy Symbiosis 680574 grants 20% critical block chance at 0, 59, and 60 Insanity and 40% at 61 Insanity.
- No other spell is reached: the change is keyed exclusively to 680574, 680603 is untouched, and no other code reads
  680574 `Effect[0]`. No existing non-conformance scenario references 680574.
- Regressions (`prove-A2`, runs `20261125-051544` and `20261125-051618`, build `23a0c7018391`, 3/3 ok, 0 flips):
  `680574 behaviour_metric_delta crit_block_at_59` (0 -> 20.0, control arm), `crit_block_at_60` (0 -> 20.0), and
  `crit_block_above_60` (0 -> 40.0). These three entries match `feat/coa-cultist-conformance` (`cu-h2`) verbatim for
  merge deduplication. `critical_block_chance` is a readback metric (`Unit::GetTotalAuraModifier`), so the prove
  fragment classifies clause 2 as `data` evidence rather than a combat-roll sample.
