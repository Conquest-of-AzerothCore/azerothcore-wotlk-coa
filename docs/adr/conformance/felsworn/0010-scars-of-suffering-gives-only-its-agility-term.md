# 0010. Scars of Suffering gives allies only 15% of the caster's Agility

- Status: accepted (owner ruling Felsworn O-20 (2026-11-23), relayed by the mentor, 2026-11-23: the talent text governs; Felsworn O-22 (2026-11-23): display
  against server cases are decided one by one)
- Date: 2026-11-23

## Context

Scars of Suffering 570158 (server Spell.dbc, Description[enUS]): "Casting Azzinoth's Assault now scars the enemy,
increasing your allies' attack power against them by ${$m1+0+$AGI*0.15} for $570159d."

`$m1` without an id reads 570158's own Effect[0] (aura 42 PROC_TRIGGER_SPELL, EffectBasePoints -1, EffectDieSides 1):
0 at any level ([ADR 0013](../../0013-conformance-expands-spell-markup.md),
[ADR 0014](../../0014-level-scaled-tooltip-values-use-the-skill-rank.md)). The talent card shows 0.15 x Agility, 19.5
at the reference Agility 130, which the client prints as 20.

The scar 570159 Effect[0] (aura 165 SPELL_AURA_MELEE_ATTACK_POWER_ATTACKER_BONUS, SpellFamilyName 20) carries
EffectBasePoints 4, EffectDieSides 1, EffectRealPointsPerLevel 0.5, BaseLevel and SpellLevel 17. Stock
`SpellEffectInfo::CalcValue` gives 4 + int32(43 x 0.5) + 1 = 26 at level 60, and the Felsworn hook
(`felsworn_scaling::ModifySpellEffectBaseValue`, data row `{570159, 0, ..., 0.15}`) adds 0.15 x Agility. The counted
pair 20261123-154742 / 20261123-154842 (build 1e433a3c0c18) read 45 in both runs against 19.5.

The debuff's own text, 570159 ToolTip[enUS] "Attackers have ${$m1+$ppl1+$AGI*0.15} increased attack power against this
target.", names the base and per-level points. The owner ruled that the talent text governs and that the debuff text
is corrected to it.

## Options

- (a) The talent card prevails: clear 570159 Effect[0] EffectBasePoints to -1 and EffectRealPointsPerLevel to 0 in
  `AscensionFelsworn::ApplyContracts`, so the hook's Agility term is the whole amount.
- (b) The debuff text prevails: no server change, about 46 at level 60.
- (c) Base without per-level points, 24.5: no client text shows it.

## Decision

Option (a), keyed to 570159 (SpellFamilyName 20) in the Felsworn contracts, next to the 805241 and 803715 lines that
cleared per-level points or base points the same way ([Felsworn ADR 0002](0002-tyrants-gaze-heals-its-displayed-points-and-generates-one-felfury.md)).
The engine is untouched.

## Consequences

- `CalcValue` now returns -1 + 1 = 0 before the hook, and the hook adds 0.15 x Agility. The final `int32(value)` of
  `CalcValue` truncates: 19.5 at Agility 130 is stored as 19, where the client prints 20; 24 at Agility 160 is 24.
- Every ally's attack power against the scarred target rises by that amount:
  `Unit::GetTotalAttackPowerValue` adds the victim's total aura 165 modifier.
- 570159 is also the EffectTriggerSpell[0] of Doomglaive Fel-wrought Wound 555725 (SpellFamilyName 20, ToolTip
  "Recently used Doomscar.", no Description). Its text states no value; no DBC link, SQL row or class code casts it.
  If it is ever applied, its scar also carries 0.15 x Agility only.
- The debuff text 570159 ToolTip still shows base and per-level points. Its correction is a client text change
  through `coa_client_spell_description`, rendered on the lab client first, under its own approval; it is not part of
  this change.
- Regression: the class file entries `scar_amount` (reference Agility 130, expected 19.5) and `scar_amount_agility`
  (Agility 58451 adds 30, expected 24), each judged to 1 with a control read of 0 before the talent is learned.
