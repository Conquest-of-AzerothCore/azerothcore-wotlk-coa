# 1294. Offensive dispel resist rate judges buff survival through Aura::CalcDispelChance

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39

## Context

Three Cultist (class 25) claims state an increased chance for a positive buff to resist enemy dispels:

- Void-Enchanted Armor 804633: `"Increases your chance to resist dispel effects by $s1%."` Shipped `Spell.dbc` carries
  `EffectBasePoints[0] = -21` (`-20`), which `data/sql/updates/pending_db_world/rev_20260922_03_cultist_void_enchanted_armor.sql`
  overrides in `spell_dbc` to `EffectBasePoints_1 = 19`, `EffectDieSides_1 = 1`, giving an effective value of `+20`
  (`SPELL_AURA_MOD_DISPEL_RESIST`, aura 235).
- Forbidden Resilience 300287: `"While Herald of the Depths is active, ... have a $s1% increased chance to resist
  dispel effects."` `AscensionCultistContracts.cpp:110-111` configures effect 0 as `SPELL_AURA_MOD_DISPEL_RESIST`
  (`+25`), gated on Herald of the Depths 520326 in `AscensionCultist.cpp:294` and `AscensionCultistAuras.cpp:137-138`.
- Crystalline Reflection 525060: `"Increases the chance for Void Shield to resist dispel effects on allies by $s2%"`
  (`Effect[1]` aura 107 `SPELL_AURA_ADD_FLAT_MODIFIER`, `EffectMiscValue[1] = 28` `SPELLMOD_RESIST_DISPEL_CHANCE`,
  `EffectBasePoints[1] = 49`, `EffectDieSides[1] = 1` = `+50`, class mask matching Void Shield 578115).

Existing conformance kinds cannot prove these claims: `dispel_removal` and `dispel_count` test the caster dispelling
debuffs, while `debuff_resist_rate` and `taken_hit resist_rate` test incoming harmful debuff application rather than
survival of a friendly Magic buff under an enemy dispel.

`Aura::CalcDispelChance(Unit* auraTarget, bool offensive)` (`src/server/game/Spells/Auras/SpellAuras.cpp:1153-1178`)
starts at `resistChance = 0`, applies `SPELLMOD_RESIST_DISPEL_CHANCE` from `GetCaster()->GetSpellModOwner()`, adds
`auraTarget->GetTotalAuraModifier(SPELL_AURA_MOD_DISPEL_RESIST)` when `offensive` is true, clamps `resistChance` to
`[0, 100]`, and returns `100 - resistChance`. `Spell::EffectDispel` (`src/server/game/Spells/SpellEffects.cpp:3656-3695`)
skips dispelling when the returned chance is `0` and rolls `roll_chance_i(chance)` otherwise.

## Options

- Read `SPELL_AURA_MOD_DISPEL_RESIST` / `SPELLMOD_RESIST_DISPEL_CHANCE` via `effect_value` or `spell_modifier`: data
  readback only, does not exercise `Aura::CalcDispelChance` or `Spell::EffectDispel`.
- Extend `debuff_resist_rate`: tightly coupled to harmful debuff application, `low_health_pct` and `lockout` modes.
- New opt-in behaviour kind `offensive_dispel_resist_rate` in `kinds/offensive_dispel_resist_rate.py`, zero C++
  changes, using the existing harness `set_aura` + creature `cast` (instant Dispel Magic 527) + `aura` read.

## Decision

Add `kinds/offensive_dispel_resist_rate.py` ([doc](../../apps/coa-gameplay-test/conformance/docs/kinds/offensive_dispel_resist_rate.md)):

- Applies a `Spell.dbc`-validated positive Magic buff (`Dispel == 1`) on `"caster"` or a grouped `"ally"` player with
  `caster: "caster"` (so `GetCaster()` owns `SPELLMOD_RESIST_DISPEL_CHANCE`), then has a stationary passive hostile
  striker (creature `36`, `reaction: 0`, `spell_hit_bonus: 100` so `MagicSpellHitResult` adds 0% miss) cast an instant
  Magic dispel (`527` Dispel Magic by default) and immediately reads `aura` of the buff on the holder.
- Computes expected survival rates through `clamped_survive_rate(resist_pct) = min(100, max(0, resist_pct)) / 100`,
  matching the `[0, 100]` clamp in `Aura::CalcDispelChance`.
- Runs a `control` arm before a real `learn` of `spell` (showing its own base rate, typically `0%`), a `treatment` arm
  after learning `spell`, and when `gate_cast` is set a `gate_off` arm with `spell` learned and `gate_cast` removed
  (verifying the gate aura before and after each arm; a failed precondition voids the arm as `unmeasured`).
- Sizes trials per arm (pooled over `parts`) with exact binomial calculation through the judge (Wilson 99% interval
  inside the G-20 band `max(5% * p, 2 pt)` for interior rates; exact survival for clamped `0.0` / `1.0` bounds) so that
  both conformant false-fail probability and cross-arm false-pass probability per counted pair of 2 runs are at most
  `residual` (default `1e-3`, 0.1%), stated in the contract.
- Refuses entries whose clamped rates are equal, whose combined G-20 bands overlap, or whose sample size leaves either
  the pair false-fail or pair false-pass probability above `residual`.
- Evidence class: uses `BEHAVIOUR_METRIC_DELTA` with metric `aura` (already `EVENT` in `coverage.METRIC_EVIDENCE`), so
  every passing verdict counts directly as `behaviour` without touching `coverage.py`.

## Consequences

- Opt-in new kind module, auto-discovered by `kinds/__init__.py`; zero edits to shared core files and zero change to
  finished-class scenarios.
- Closes Cultist 804633 Void-Enchanted Armor (`+20%`), 300287 Forbidden Resilience (`+25%` gated on Herald 520326), and
  525060 Crystalline Reflection (`+50%` on Void Shield 578115 on a grouped ally).
- Seeded unit tests cover `ok`, `alert`, `unmeasured`, refusals (equal/overlapping/undersized/clamped-equal/bad spell),
  clamping bounds (`-20`, `0`, `100`, `125`), and a mutant wrong expectation (`30%` against `20%` data).
