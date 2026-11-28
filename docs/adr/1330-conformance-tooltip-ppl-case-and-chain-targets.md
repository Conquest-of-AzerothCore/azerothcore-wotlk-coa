# 1330. Case-insensitive `$PPL`, opt-in standalone `$xN`, and opt-in `$bh`/`$BH` in `tooltip.py`

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-27
- Rulings: Sun Cleric (class 27) `extra_spells` catch-up (`502411` *Radiant Cascade*, `502429` *Illumination*, `572157` *Solar Invocation: Ascension*, `572035` *Daybreak*)

## Context

Catching up Sun Cleric's server-granted `extra_spells` (class 27, per ADR 1327) surfaced three tooltip-parsing gaps in
`apps/coa-gameplay-test/conformance/tooltip.py`:

1. **Uppercase `$PPL<N>` (`502411` *Radiant Cascade*, `572157` *Solar Invocation: Ascension*)**: `Spell.dbc` contains
   3,090 lowercase `ppl` tokens and 52 uppercase `PPL` tokens (`${$m1+$PPL1+$SP*3.10}`, `${$m1+$PPL1+$bh*0.141131}`).
   `Tooltip.math_variable` (`tooltip.py:514`) and `ExpressionParser.primary` (`tooltip.py:786`) matched only exact
   lowercase `'ppl'`. None of the seven finished classes currently contain uppercase `$PPL<N>`, so case-insensitive
   matching has zero snapshot impact.
2. **Standalone `$x<N>` / `$X<N>` (`502411` *Radiant Cascade*: `"jumps to up to $x1 additional allies"`)**:
   `CHAIN_TARGET_LETTERS = 'xX'` was previously resolved only inside `${...}` expressions (ADR 0726). However, scanning
   all seven finished classes reveals nine spells whose committed value-scenario snapshots currently record standalone
   `$x1`/`$<id>x1` as `unreadable`:
   - Witch Doctor (class 13): `802262`, `803846` (`$500473x1`)
   - Cultist (class 25): `503487`, `503488`, `524876`, `572140`, `572141`, `572715`, `804208` (`$x1`)
   Reading standalone `$xN`/`$XN` unconditionally would alter `manifest.json` and nine value scenarios across Witch
   Doctor and Cultist.
3. **`$bh` and `$BH` bonus healing (`502411` `$bh*0.141131`, `502429` `$bh*1.05`, `572035` `$BH*0.595`)**:
   `Tooltip.caster_value` (`tooltip.py:486-499`) supported neither `$BH` nor `$bh`, `CasterStats` had no
   `bonus_healing` field, no class file measures `healing_power` in `reference_stats`, and `test_tooltip.py:550`
   explicitly asserts `${$BH*1}` stays unreadable when bonus healing is unavailable. Across the seven finished classes,
   76 spells currently carry `$BH` or `$bh` as `unreadable` (18 in Witch Doctor, 39 in Cultist, 19 in Sun Cleric);
   aliasing `$bh`/`$BH` unconditionally to `sp_by_school` would both conflate distinct WotLK stats (`healing_power` vs
   school spell damage power) and drift three finished class snapshots.

## Options

- Resolve all three unconditionally in `tooltip.py`: rejected, because unconditional standalone `$xN` drifts Witch Doctor
  (13) and Cultist (25) snapshots, and unconditional `$bh`/`$BH` aliasing drifts Witch Doctor (13), Cultist (25), and
  Sun Cleric (27) snapshots while inventing a `healing_power == sp_by_school` assumption.
- Make `ppl` case-insensitive unconditionally (zero finished-class diff), gate standalone `$xN`/`$XN` behind an opt-in
  `standalone_chain_targets: bool = False` parameter on `Tooltip` / `read_tooltip`, and gate `$BH`/`$bh` behind an
  opt-in `bonus_healing: float | None = None` field on `CasterStats`. Chosen.

## Decision

1. **Case-insensitive `ppl` in `tooltip.py`**:
   - Match `name[:-1].lower() == 'ppl' and name[-1:] in EFFECT_DIGITS` in `Tooltip.math_variable`.
   - Exclude `name[:-1].lower() != 'ppl'` from `ExpressionParser.effect_indices` so uppercase `$PPL<N>` preserves ADR 1328
     multi-effect attribution (single-effect expressions like `${$m2+$PPL1}` keep `effect_index = 1`).
2. **Opt-in standalone `$xN`/`$XN` in `tooltip.py`**:
   - Add `standalone_chain_targets: bool = False` to `Tooltip.__init__` and `read_tooltip`, propagated through
     `Tooltip.expansion`.
   - When enabled, `Tooltip.spell_token_value` reads `$xN`/`$XN`/`$<id>xN`/`$<id>XN` (`N in '123'`, unscaled) as
     `Displayed(..., float(EffectChainTarget[N-1]), None, 'count', None)`, matching `$u`/`$i` and expression `$xN`
     (ADR 0726). Bare `$x` or out-of-range `$x4` remains unreadable.
3. **Opt-in `$BH`/`$bh` via `CasterStats.bonus_healing`**:
   - Add `bonus_healing: float | None = None` to `CasterStats`.
   - In `Tooltip.caster_value`, resolve `name in ('BH', 'bh')` to `self.caster.bonus_healing` when `bonus_healing is not
     None`, keeping mixed-case `$Bh`/`$bH` and unmeasured (`bonus_healing=None`) expressions unreadable, matching the
     exact convention of `('SP', 'sp')`, `('PL', 'pl')`, and `EFFECTIVE_STATS`.

## Consequences

- Zero snapshot drift across all finished classes (`13`, `14`, `15`, `19`, `23`, `25` match committed digests; `27`
  matches its pre-edit tree digests byte-for-byte).
- `572157` (*Solar Invocation: Ascension*) `${$m1+$PPL1+$SP*3.10}` now parses cleanly by default. Note that because
  `572157` has a `SkillLineAbility` row (`line=96`), `$m1` (ADR 0014) and `$PPL1` (ADR 0031) each add
  `EffectRealPointsPerLevel[0] * (60 - BaseLevel)`; downstream Sun Cleric value/hit checks should account for that
  existing ADR 0014 + ADR 0031 behavior rather than altering `$m1` semantics silently.
- Callers that opt into `standalone_chain_targets=True` or populate `CasterStats.bonus_healing` can read standalone
  `$x1`/`$X1` (`502411` -> `4.0`, `'count'`) and `$bh`/`$BH` (`502411`, `502429`, `572035`) with full unit-test
  coverage in `apps/coa-gameplay-test/conformance/test_tooltip.py`.
