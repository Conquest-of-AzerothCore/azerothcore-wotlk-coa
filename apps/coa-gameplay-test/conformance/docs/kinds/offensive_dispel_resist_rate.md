# Offensive dispel resist rate (`behaviour_metric_delta`, `kind: "offensive_dispel_resist_rate"`, ADR 1294, provisional)

ADR 1294 has a provisional number and is renumbered at merge (guide 14.4).

Measures the rate at which a positive Magic buff on the caster (or a grouped ally) survives a hostile creature's instant
Magic dispel through `Aura::CalcDispelChance` (`src/server/game/Spells/Auras/SpellAuras.cpp:1153-1178`) and
`Spell::EffectDispel` (`src/server/game/Spells/SpellEffects.cpp:3656-3695`).

## Engine formula and bounds

`Aura::CalcDispelChance(Unit* auraTarget, bool offensive)` starts with `resistChance = 0`, adds
`SPELLMOD_RESIST_DISPEL_CHANCE` from the aura caster's spell mod owner (and the Pyromancer 706650 special case), adds
`auraTarget->GetTotalAuraModifier(SPELL_AURA_MOD_DISPEL_RESIST)` when `offensive` is true, clamps `resistChance` to
`[0, 100]`, and returns `100 - resistChance`. `Spell::EffectDispel` skips dispelling when the returned chance is `0`
and rolls `roll_chance_i(chance)` otherwise.

The expected survival rate is therefore `clamp(resist_pct, 0, 100) / 100`. Raw values below `0` clamp to `0.0` and raw
values above `100` clamp to `1.0`.

## Scenario and arms

A stationary passive hostile striker (creature `36`, `reaction: 0`, `spell_hit_bonus: 100` so `MagicSpellHitResult`
cannot add a 4% miss rate) casts `dispel_spell` (default `527` Dispel Magic, validated in `Spell.dbc` as an instant
Magic dispel) at `target` (`"caster"` by default, or `"ally"` for a grouped ally player). Before every trial,
`buff_spell` (validated in `Spell.dbc` as `Dispel == 1`) is applied to `target` with `caster: "caster"` (so
`GetCaster()` owns `SPELLMOD_RESIST_DISPEL_CHANCE`); immediately after the dispel, `aura` of `buff_spell` is read on
`target`.

- `control`: runs before `spell` is learned, expecting `clamp(control_resist_pct, 0, 100) / 100` (default `0.0`).
- `treatment`: runs after a real `learn` of `spell`, expecting `clamp(treatment_resist_pct, 0, 100) / 100`.
- `gate_off` (when `gate_cast` is set): `gate_cast` is cast before `control` and `treatment` (read present before and
  after each arm; missing or absent voids the arm as `unmeasured`), then removed before `gate_off` (read absent before
  and after) while `spell` stays learned, expecting the control rate. Produces two labels: `<suffix>` (`control` +
  `treatment`) and `<suffix>_gate_off` (`control` + `gate_off`).
- `gate_auras` (optional, requires `gate_cast`; ADR 1314, provisional): list of `[spell, stacks]` pairs emitted as
  `set_aura` on `caster` immediately before `required_aura_steps` and the `gate_cast` in `control` and `treatment` (not
  in `gate_off`). Holds a backing resource aura (such as Insanity `500706`) with margin above a derived marker
  threshold so periodic refresh ticks cannot strip the `CasterAuraSpell` marker between `set_aura` and `cast`. Omitting
  `gate_auras` leaves the generated scenario byte-identical.

## Sizing, judgement and refusals

- Interior rates (`0 < p < 1`) are judged by their pooled Wilson 99% interval inside the G-20 band
  `max(5% * p, 2 pt)`. Clamped boundary rates (`0.0` or `1.0`) require exact survival (`0` of `N`, or `N` of `N`).
- Both conformant false-fail probability and cross-arm false-pass probability (exact binomial through the judge) are
  sized to at most `residual` (default `1e-3`, 0.1%) per counted pair of 2 runs and stated in the contract.
- The kind refuses any entry whose clamped control and treatment rates are equal, whose combined G-20 bands overlap, or
  whose sample size leaves either the pair false-fail or pair false-pass probability above `residual`.
