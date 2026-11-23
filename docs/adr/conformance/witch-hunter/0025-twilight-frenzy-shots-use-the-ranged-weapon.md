# 0025. Twilight Frenzy shots use the ranged weapon

- Status: accepted
- Date: 2026-11-17

## Context

Twilight Frenzy 805751 reads: "Spin around for $d, firing shots at nearby enemies for $805753s2% Ranged Weapon Damage
plus ${$cond($gt($sps, $sph), $805753m1+$805753ppl1+$sps*.2+$RAP*.1, $805753m1+$805753ppl1+$sph*.2+$RAP*.1)} as
Twilight Damage. Can dodge and parry and move while active." (Spell.dbc server set, Description[enUS]). The channel
requires a ranged weapon (EquippedItemClass 2, EquippedItemSubClassMask 262156: bow, gun, crossbow) and fires the shot
805753 every 500 ms through 805752.

805753 has DmgClass 3 (ranged), Effect[1] 31 WEAPON_PERCENT_DAMAGE 50%, EquippedItemClass -1, EquippedItemSubClassMask
0 and no SPELL_ATTR0_USES_RANGED_SLOT. `Spell::Spell` gives a ranged spell `RANGED_ATTACK` only when
`SpellInfo::IsRangedWeaponSpell` holds (`Spell.cpp:605-606`), and that needs family Hunter, a ranged subclass mask or
the ranged-slot attribute (`SpellInfo.cpp:1442-1446`). 805753 has none, so it took `BASE_ATTACK` and
`Spell::EffectWeaponDmg` read the main-hand damage (`SpellEffects.cpp:4719`, `Unit.cpp:3588-3590`). The sibling Witch
Hunter shots 807527 and 807284 carry mask 262156.

Measured before the change, run 20261117-144749 (worldserver sha256 10733f3c8ee0, server commit 66191e9764), one run:
`805751 behaviour_hit_ratio shot_sp` read 2.964 against 2.7029 (alert), and the unresisted hit clusters, about 104
(control), 286 (+1000 attack power) and 303 (+1000 spell power), match the main-hand model (Inquisition 2027,
103.7 / 285.8 / 303.7), not the ranged-weapon model of the tooltip (117.45 / 317.45 / 317.45).

The cause is client data under a stock engine rule; no CoA code set the attack type. Mentor D-467 settled the fix as
owed under the owner's principle; D-473 chose form (B). The precedents are
[ADR 0007](0007-witch-hunter-shots-have-no-ranged-preparation.md) (a stock ranged rule corrected for named Witch
Hunter spells only, D-157) and [ADR 0015](0015-twilight-frenzy-can-dodge-and-parry-while-channelling.md) (a Witch
Hunter-only gate keyed on 805751).

## Options

- (A) Set SPELL_ATTR0_USES_RANGED_SLOT on 805753, as the siblings. It also adds 500 ms to a direct non-triggered cast
  (`SpellInfo::CalcCastTime`), a projectile flag and ammo data in the cast packets, and a client stream cast-time row.
- (B) Set EquippedItemSubClassMask 262156, the parent's mask, on 805753 and keep EquippedItemClass -1. With class -1
  the mask is read by no other path that reaches this spell.
- (C) No change: the tooltip's "Ranged Weapon Damage" stays contradicted.

## Decision

Option (B). `AscensionWitchHunter::ApplyContracts` sets EquippedItemSubClassMask 262156 on 805753 when its DBC row
still has EquippedItemClass -1 and mask 0. No engine file, no SQL, no client text, no other spell or class.

## Consequences

`IsRangedWeaponSpell()` is true for 805753, so the shot takes `RANGED_ATTACK` (D-374 list, fix note 379.0):

- Weapon part: 50% of the ranged weapon damage (`UNIT_FIELD_MIN/MAXRANGEDDAMAGE`, with ranged attack power / 14 times
  the ranged speed) instead of the main hand. The flat part and its RAP x 0.1 and spell power x 0.2 terms are
  unchanged: the Witch Hunter coefficient hook reads ranged attack power explicitly, and the 805753
  `spell_bonus_data` row is all zero.
- Ranged crit: the shot's crit chance reads the ranged crit percentage instead of the melee one
  (`SpellDoneCritChance` with the spell's attack type, Spell.cpp:8662; PLAYER_CRIT_PERCENTAGE vs
  PLAYER_RANGED_CRIT_PERCENTAGE, Unit.cpp:10298, 10304; SpellTakenCritChance, Spell.cpp:8664).
- Ranged hit skill: the hit table was already the ranged one (DmgClass 3, no dodge or parry); the attacker skill term
  becomes the ranged weapon skill instead of level x 5 (Unit.cpp:3756-3767, 4591-4600), equal when the weapon skill is
  at its maximum. Weapon skill gains go to the ranged weapon skill (UpdateCombatSkills, Unit.cpp:14237).
- Ranged-slot item procs and PPM: chance-on-hit and enchant procs come from the ranged-slot item, no longer the
  main-hand item (Spell.cpp:2972-2974, Player.cpp:7806-7821); a PPM chance uses the ranged attack time
  (SpellAuras.cpp:2366-2368).
- Ranged attacker bonuses (Unit.cpp:11442-11467; ranged damage-taken auras Unit.cpp:11638-11641, 11692-11698): the
  stock flat term of `MeleeDamageBonusDone` uses the victim's ranged attacker bonus and
  ranged attack power versus auras, times the ranged speed, instead of the melee ones (Slayer's Mark 804073 carries
  both); the Witch Hunter ranged bonus term of [ADR 0021](0021-slayers-mark-ranged-bonus-reaches-the-rap-rows.md) on
  805753 effect 0 is unchanged. Damage-taken auras on the victim are the ranged ones.
- Unchanged: the Twilight school (the wand override is for wand classes only), ammo (not consumed by Ascension
  classes), range, haste, the off hand, the weapon requirement (class -1 skips the equipped-item checks) and swing
  timers.
- What the player sees: the damage numbers and crit rate of each Frenzy shot. No tooltip or spellbook text changes.
- Regression in `classes/witch_hunter.json` (claim 379.0): `805751 behaviour_hit_ratio shot_sp` (+1000 spell power,
  aura 10030) and `shot_rap` (+1000 attack power, aura 10031), each against the no-aura control arm, expected 2.7029
  (117.45 / 317.45 at the reference character with the Boltslinger crossbow 15809), 160 trials x 5 parts per arm. The
  main-hand reading 2.964 alerts on `shot_sp`; `shot_rap` cannot tell the weapon source (main hand 2.756, inside its
  band) and is a second witness.
- Measured after the change, counted pair 20261117-152917 / 20261117-153017 (worldserver sha256 aefdc4216bd5, server
  commit 04dfb5da11), 800 trials per arm, both runs ok: `shot_sp` 2.7075 and 2.6997, `shot_rap` 2.7071 and 2.7045
  (99% half-widths 3.1 to 3.3 points against the 8.5-point band). The unresisted hits read 117 (control) and 317
  (+1000 attack power, +1000 spell power) in both runs, the ranged-weapon model; the other Twilight Frenzy labels
  (805751, its shot 805753, Twilight Frenzy talents 503680 and 705499) read as in the count of record.

## References searched

~/CoaServer/reference snapshots (bindmysoul talents, coabuildhub spells_master_index / spells_missing,
mind_of_ascension_talent.csv): Twilight Frenzy talents only, nothing on the shot's weapon source. Videos
video-boltslinger-HwCt84i9iKA [8:44] and video-overview-3qLYu74QhH4 [34:20] show "50% Ranged Weapon Damage" (older
state, lead only). coa-history: 805753 13852 SPELL_DAMAGE in 8 logs (mean 671), which cannot separate the weapon
source. coa-server-guide docs: nothing found.
