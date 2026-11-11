# 0146. Bursting Impact raises Zealotry through its weapon damage multiplier

- Status: accepted
- Date: 2026-11-11

## Context

Bursting Impact 705276 reads "Increases your off-hand weapon damage by $s1%." ($s1 = 25, aura 122
`SPELL_AURA_MOD_OFFHAND_DAMAGE_PCT`). Zealotry 801450 reads "Deals $s2% off-hand Weapon Damage as Holy Damage."
The Templar gap batch measured plain off-hand swings +25% but Zealotry +1.0% and -0.2% with the talent
(`lean/gap-batch-report.md`). The owner ruled on 2026-11-11 that Bursting Impact must raise Zealotry; the mentor
decided that it multiplies with Blade Sermon (`method-study/owner-rulings-2026-11-10.md`).

Cause, by code reading (`lean/bursting-impact-fix-note.md`): `Spell::EffectWeaponDmg` asks a non-physical spell for
weapon damage without the total-percent factor (`SpellEffects.cpp:4719`, `StatSystem.cpp:732`), and aura 122 acts
only through the off-hand `TOTAL_PCT` (`Unit::UpdateDamagePctDoneMods`). That stock rule also drops the 0.5 off-hand
penalty from Zealotry.

## Options

- Change the stock rule in the core. Refused: it applies to every class and would also bring the 0.5 penalty into
  Zealotry.
- Scale the final damage in `OnSpellCalculatedTarget`, as Judgement does. Same ratio, but it scales the hit rather
  than the weapon damage the tooltip names.
- Set Zealotry's script weapon damage multiplier before its effects run.

## Decision

`templar_casts::OnSpellBeforeEffects` (`AscensionTemplarAbilities.cpp`) calls
`Spell::SetScriptWeaponDamageMultiplier(1 + amount / 100)` for 801450, with the amount read from 705276 effect 0,
when the caster has a usable off-hand weapon (`Player::GetWeaponForAttack(OFF_ATTACK, true)`). The check comes
before the hook's triggered-cast return, because Zealotry is always cast triggered. Zealotry's `EquippedItemClass`
is -1, so `Spell::CheckItems` skips its off-hand check and Zealotry can fire with an empty off hand; the weapon test
keeps the talent from scaling the attack-power-only hit there. The multiplier applies after Blade Sermon's flat
weapon percent (`SpellEffects.cpp:4722`), so the two multiply.

## Consequences

- Zealotry with Bursting Impact is 100% of off-hand weapon damage (80% x 1.25); with Blade Sermon rank 2 125%.
  Without the talent it stays at 80%, and the stock rule is unchanged for every other spell.
- `SetScriptWeaponDamageMultiplier` stores a value: a later Templar caller on 801450 would overwrite this one. Blade
  Sermon raises the weapon percent through a spell modifier and does not call the setter, so the combined arm
  (1.5625) catches only an overwrite by a caller active under Bursting Impact and Blade Sermon together.
- Regression: catalog scenario `templar-bursting-impact-zealotry` (1.22-1.28 between two forced-crit hits) and the
  conformance arms `705276` `zealotry`, `share` (at the reference attack power, off-hand Cudgel 2492),
  `blade_sermon`, `empty_off_hand` and `swing`. Without the talent Zealotry's percent is read from the judged
  Blade Sermon rank 2 ratio, (p + 20) / p.
