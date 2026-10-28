-- Free-pick Hero Hunter tree: abilities and talents doing what their Ascension tooltips say.
--
-- Mongoose Bite 1495-53339: "{11+SP*0.45+AP*0.45}". Stock rows carry 20% attack power and no spell power.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (1495, 1496, 14269, 14270, 14271, 36916, 53339);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1495, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(1496, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(14269, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(14270, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(14271, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(36916, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite'),
(53339, 0.45, 0, 0.45, 0, 'Hunter - Mongoose Bite');

-- Wing Clip 2974: "{RAP*0.4+96}" (ranged attack power: AscensionHeroHunter sets UseRangedAttackPowerForDamage).
DELETE FROM `spell_bonus_data` WHERE `entry` = 2974;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(2974, 0, 0, 0.4, 0, 'Hunter - Wing Clip');

-- Entrapment 19184/19387/19388: "When your Frost Trap or Snake Trap is triggered you entrap all afflicted targets".
-- The stock row has no proc flags and Spell.dbc none either: listen to trap activation; the script roots the target.
DELETE FROM `spell_proc` WHERE `SpellId` = -19184;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-19184, 0, 9, 0x00000010, 0x00002000, 0, 0x00200000, 0, 6, 0, 2, 0, 0, 0, 0, 0);
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_hunter_entrapment';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-19184, 'aura_hero_hunter_entrapment');

-- Concussive Barrage 35100/35102: "Your successful Chimera Shot and Multi-Shot attacks ... Daze the target". The stock
-- row and Spell.dbc carry no proc flags.
DELETE FROM `spell_proc` WHERE `SpellId` = -35100;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-35100, 0, 9, 0x00001000, 0, 0x00000001, 0x00000100, 1, 2, 0, 0, 0, 0, 0, 0, 0);

-- Wild Quiver 53215-53217: "when dealing damage with your Auto Shot or Steady Shot". The stock row names Auto Shot
-- only.
DELETE FROM `spell_proc` WHERE `SpellId` = -53215;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-53215, 0, 9, 0x00000001, 0x00000001, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0);

-- Savage Retaliation 19298 capstone: "Your Mongoose Bite and Raptor Strike critical hits now lower the internal cooldown
-- of Killer Instinct. This effect has a 4 seconds cooldown." Spell.dbc carries no proc flags.
DELETE FROM `spell_proc` WHERE `SpellId` = 19298;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(19298, 0, 9, 0, 0, 0x02010000, 0x00000010, 1, 2, 0x00000002, 0, 0, 0, 0, 4000, 0);

-- Resourcefulness 34493 capstone: "Dealing damage with Immolation Trap, Explosive Trap or Black Arrow reduces the cooldown
-- of your Mongoose Bite, Raptor Strike and Glaive Toss by 1 second ... not more than once every second." Spell.dbc
-- carries no proc flags; its 734493 uses effect 197, now handled by the core.
DELETE FROM `spell_proc` WHERE `SpellId` = 34493;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(34493, 0, 9, 0, 0x00000040, 0x00024000, 0x00050100, 1, 2, 0, 0, 0, 0, 0, 1000, 0);

-- Improved Glaive Toss 956033 capstone: "if you are further than 15 yards away targets hit are slowed by 30% for 3 sec."
-- Spell.dbc carries no proc flags; the script checks the range. The glaives hit through triggered spells
-- (PROC_ATTR_TRIGGERED_CAN_PROC).
DELETE FROM `spell_proc` WHERE `SpellId` = 956033;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(956033, 0, 9, 0, 0, 0x01000000, 0x00000100, 1, 2, 0, 2, 0, 0, 0, 0, 0);
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_hunter_improved_glaive_toss';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(956033, 'aura_hero_hunter_improved_glaive_toss');
