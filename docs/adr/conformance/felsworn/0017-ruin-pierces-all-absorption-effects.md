# 0017. Ruin pierces all absorption effects

- Status: accepted (Felsworn mentor decision D-71, 2026-11-23)
- Date: 2026-11-23

## Context

Ruin, every rank of the 801895 chain (801895, 501292 to 501299): "Bring doom upon an enemy, dealing
${$cond($gt($spfi, $sps), $m1+0+$spfi*1, $m1+0+$sps*1.32)} Shadowflame Damage to an enemy, piercing all absorption
effects." The sentence is the same on all nine ranks of the server DBC set and carries no amount, condition or shield
type.

Server DBC set: 501298 has Attributes 0x10000, AttributesEx3 0x100000 and AttributesEx4 0x800, none of which skips
absorbs. `Unit::CalcAbsorbResist` skips absorbs for a spell only through `SpellInfo::AscensionIgnoreAbsorb` or
`SpellInfo::AscensionIgnoreAbsorbAndResistance`, which the class contracts set per spell (Cultist 805116, Primalist
Magma Fissure, Pyromancer and Templar spells). The Felsworn contracts set neither.

Measured before the fix (A-5 pair, runs 20261123-212206 and 20261123-212244, build b0b5193f5a71): Staffguard 706583
fixed at 5000 on the dummy fell to 2728 and 2748 after one Ruin 501298, and Ruin's damage to health was 0 in both
runs. Felwrath 520693 depleted the same shield to 3735 and 3692.

## Decision

`AscensionFelsworn::ApplyContracts` sets `AscensionIgnoreAbsorb` on every spell of the Ruin chain (`Named(info,
801895)`). The absorb-only flag is used because the tooltip names absorption and not resistances.

## Consequences

- Ruin's hit reaches health in full through school absorbs and mana shields, and the shields keep their amount.
  Resists still apply.
- Keyed to the 801895 rank chain. The Inner Demon damage over time 805748 is a separate spell and keeps being absorbed.
  No other class file, fixture or script names a spell of the chain. The flag's only reader is
  `Unit::CalcAbsorbResist`; no engine, SQL, DBC or client text change.
- Regressions: the entries `pierce_shield` (shield 5000 before and after one Ruin), `pierce_damage` (Ruin's own damage
  to health 2163 to 2317 with the shield up, the unshielded roll at 0 spell power) and the control
  `pierce_shield_control` (Felwrath depletes the same shield to 2600 to 4800).
