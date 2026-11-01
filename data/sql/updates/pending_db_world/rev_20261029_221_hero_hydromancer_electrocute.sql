-- Hero Hydromancer (#8330): Doused 272029 is a dummy aura, so Lightning Bolt (0x1) and Chain Lightning (0x2) damage on
-- a doused target never triggered Electrocute. The aura now procs on that damage taken and casts Electrocute 272034,
-- whose tooltip deals ${($PL*2.6+$m1)+($SP*0.13)+($AP*0.0845)} Froststorm damage, and incapacitates with 272053
-- unless the target carries the 30 sec lockout 272056.
DELETE FROM `spell_proc` WHERE `SpellId` = 272029;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(272029, 0, 11, 0x00000003, 0x00000000, 0x00000000, 0x20000, 1, 0x2, 0x3, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 272029 AND `ScriptName` = 'aura_hero_shaman_doused';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(272029, 'aura_hero_shaman_doused');

DELETE FROM `spell_bonus_data` WHERE `entry` = 272034;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(272034, 0.13, 0, 0.0845, 0, 'Hero Hydromancer Electrocute - tooltip spell power and attack power');
