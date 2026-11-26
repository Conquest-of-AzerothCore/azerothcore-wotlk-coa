# Shifted control (`metric_delta` `shifted_control`, ADR 1281, provisional)

`shifted_control` judges a gate that lowers a resistance the caster's spells meet (spell penetration) against a
control with that resistance lowered by the same amount, with no engine formula of the resist chance. It is
`{aura: [spell, effect], amount, shift, shift_spell: [spell, effect], school, tolerance_share,
discrimination_share, source, caster_level?}`:

- The main reading is the dummy's `resistance` of `school`, with `before_expected` and `expected` both `amount`: the
  fixture `aura` (a phase aura on the dummy, 1 stack, its own caster) set to `amount` by `phase_aura_amounts`.
- Three reads of `spell_resist_chance` (the caster against the dummy, `school`): the control right after the before
  reading; the shifted control, after the fixture is set to `amount - shift` (its `resistance` read too), then the
  fixture is restored; the treatment right after the after reading, the gate learned.
- `shift` is stated and checked: it must equal minus the points of `shift_spell` (a SPELL_AURA_MOD_TARGET_RESISTANCE
  whose MiscValue holds `school`) at the caster level (`SpellEffectInfo::CalcValue`: base points, points per level from
  the base level, one die side), else the entry is refused. `amount` must be at least twice `shift`, so the shifted
  fixture stays the shift above 0 (the engine floors the resistance at 0).
- `caster_level` (optional) sets the caster's level at the start of the control phase (`set_level`), before the gate is
  learned; the shift is then read at that level. `phase_caster_level` is refused with it.
- Judge: span = control - shifted control. A span at or below 1e-5 is `unmeasured` (lowering the resistance does not
  move the read: a clamp). Otherwise `ok` when control - treatment >= `discrimination_share` x span and
  |shifted control - treatment| <= `tolerance_share` x span, `alert` otherwise; `tolerance_share` must stay below
  `discrimination_share`. A main reading off `amount` or a shifted resistance off `amount - shift` is `unmeasured`.
  Measured is (control - treatment) / span, expected 1.
- Evidence: `spell_resist_chance` is a readback (`Unit::GetEffectiveResistChance` with no hit); it is behaviour only in
  the learned contrast (`coverage.CONTRAST_PROOF`) and with the words "spell penetration" or "penetration" in the
  clause (the option's `STATE_PROMISES` row). The entry sets `evidence_metric: spell_resist_chance`. It proves the
  caster's penetration as the engine applies it to the resist chance, not observed resists.

Named points: `phase_steps`, `fixtures`, `model` and `verdict`.

Felsworn: Unphased 803645 `spell_pen` (level 60, shift 60) and `spell_pen_level40` (level 40, shift 40).
