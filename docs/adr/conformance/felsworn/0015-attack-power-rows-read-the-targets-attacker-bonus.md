# 0015. Felsworn attack power rows read the target's attacker attack power bonus

- Status: accepted (mentor D-68, 2026-11-23)
- Date: 2026-11-23

## Context

Scars of Suffering's debuff 570159 ToolTip[enUS] reads "Attackers have ${$m1+$ppl1+$AGI*0.15} increased attack power
against this target." Its Effect[0] is aura 165 `SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS`
([Felsworn ADR 0010](0010-scars-of-suffering-gives-only-its-agility-term.md)). Stock reads that aura wherever attack
power meets a victim: `Unit::GetTotalAttackPowerValue` with a victim (Unit.cpp:13776, 13786), the attack power term of
`Unit::SpellDamageBonusDone` (Unit.cpp:9962-9965) and `Unit::MeleeDamageBonusDone` (Unit.cpp:11518-11545).

Felsworn abilities take their attack power term from the class data (`FelswornCoefficients`) in
`felsworn_scaling::ModifySpellEffectBaseValue`, which reads `GetTotalAttackPowerValue(BASE_ATTACK)` with no victim:
the hook has no target (SpellInfo.cpp:523). `Unit::SpellDamageBonusDone` adds the victim term only with an attack
power coefficient of its own, and Tyrant's Gaze 805240 ("dealing ${$m1+0+$AP*0.35} Shadowflame Damage") has none: its
`damage_ap` entry reads exactly 344 + int(0.35 x attack power). So the Gaze ignores the scar, where the tooltip
coefficient gives 344 + int(0.35 x 331) = 459 against the scar of 19 instead of 453.

The D-61 diagnostic (453 in both arms, pair 20261123-194225 / 20261123-194305) did not show this: keyed to 805240, it
ran with the Tyrant weapon set, under which Azzinoth's Assault 801904 fails with SPELL_FAILED_EQUIPPED_ITEM_CLASS, so
the dummy was never scarred. The regression is keyed to Scars of Suffering 570158 and runs with the Slayer set.

Two classes already add the aura by hand:
- Ranger (`AscensionRangerScaling.cpp:44-46, 92, 138`): a per-spell SpellScript adds the signed aura total to attack
  power before the coefficient, at effect launch, so the engine applies its modifiers afterwards. Each spell is bound
  through `spell_script_names` SQL.
- Witch Hunter ([Witch Hunter ADR 0024](../witch-hunter/0024-slayers-mark-melee-bonus-reaches-the-ap-rows.md);
  `AscensionWitchHunterCompletion.cpp:53-70`, `AscensionWitchHunterAbilities.cpp:101-125`): table-driven over the class
  rows in `OnSpellCalculatedTarget`, the term passed through the done and taken modifiers by marginal shares.

## Options

- (a) Ranger placement: a SpellScript per Felsworn spell. Closest to stock, but one `spell_script_names` SQL binding
  per spell, which the task forbade (no SQL change), and a list to keep in step with the data rows.
- (b) Witch Hunter placement with stock arithmetic: every Felsworn row with an attack power coefficient adds
  coefficient x the target's signed aura 165 total on a damage effect, per target, before the class's own factors,
  through the engine's done, taken and area functions.
- (c) A case for Scars of Suffering only.

## Decision

Option (b), with the stock sign: the signed aura total is read as in Unit.cpp:9962 and 13786, where the Witch Hunter
keeps only a positive total (`AscensionWitchHunterCompletion.cpp:59`), so a negative attacker bonus lowers the term as
it lowers stock attack power. In Felsworn class code only (`Owner()` requires class 14; rows from `FelswornCoefficients`):
- direct damage and normalized weapon damage effects at launch; a normalized weapon row takes the spell's own attack
  type as `Spell::Spell` sets it (Spell.cpp:597-615), so the off-hand strike of Azzinoth's Assault 572585
  (`SPELL_ATTR3_REQUIRES_OFF_HAND_WEAPON`) scales the term by the off-hand `UNIT_MOD_DAMAGE_OFFHAND` TOTAL_PCT
  (0.5 at base, Unit.cpp:519) and passes `OFF_ATTACK` to the melee done and taken modifiers, as
  `Spell::EffectWeaponDmg` does for its fixed bonus (SpellEffects.cpp:4689-4708); and the value a
  `SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE` row hands its triggered spell (Immolation Aura -> 800208), in
  `felsworn_casts::OnSpellCalculatedTarget` (`AscensionFelsworn::AddVictimAttackPower`);
- health leech effects (Felspill 555742), whose damage is computed at hit, in
  `felsworn_scaling::ModifySpellDamageTaken`;
- persistent area aura periodic damage (Sunder 556503), whose ticks take done and taken modifiers after the hook
  (SpellAuraEffects.cpp:6643-6655), as a raw term in `felsworn_scaling::ModifyPeriodicDamageAurasTick`.

Healing, absorb and self rows read no victim term, as in stock (Unit.cpp:10923). Class 14 has no ranged attack
power row, so only the melee aura is read. The engine is untouched.

## Consequences

- Against a target scarred for 19, Tyrant's Gaze deals 459 instead of 453 (+int(0.35 x 19) = +6 per hit).
- The bonus term is truncated on its own: at most 1 point below stock's single truncation, before modifiers.
- Chain damage multipliers are not applied to the term; the only chained attack power rows (805240 Effect[0], 25
  targets; 804766 Effect[0], 1 target) carry EffectDamageMultiplier 1.0.
- A periodic damage row on a unit aura, a ranged attack power row, or an infernal's owner-scaled damage
  (AscensionFelswornSummons.cpp:57) would not read the target's aura; none of the first two exists in class 14, and the
  infernal's own swings read the aura through the engine.
- Against the same scar the off-hand strike 572585 gains int32(0.145 x 19) = 2 x 0.5 = 1 before modifiers, the
  main-hand strike 520262 gains 2.
- Regressions, class file entries keyed to 570158: `scar_ap_gaze` (Tyrant's Gaze observed, hit_ratio, expected
  1.01325, control arm without the scar); `scar_ap_gaze_pin` (metric_delta, the scarred Gaze hit 459 within 1, which
  excludes no term, 453, and a doubled term, 466); `scar_ap_offhand` (metric_delta, the off-hand strike against a
  scar fixture of 200100: gain 68 to 74 + the stock flat 34302 + the off-hand share 14507, excluding the main-hand
  share 29014).
