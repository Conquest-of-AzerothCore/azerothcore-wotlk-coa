-- Warcraft Reborn Warlock: Backdraft and Everlasting Affliction proc like their stock talents, Master Demonologist, Soul Link and Summoner's Armor reach the Reborn demons, Reign of Dread follows Nemesis.
DELETE FROM `spell_proc` WHERE `SpellId` IN (-1147258, -1147201);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1147258, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -47258;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1147201, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -47201;

DELETE FROM `spell_pet_auras` WHERE `spell` IN (1123785, 1123822, 1123823, 1123824, 1123825, 1119028, 1701521);
INSERT INTO `spell_pet_auras` (`spell`, `effectId`, `pet`, `aura`) VALUES
(1123785, 0, 1100416, 1123759),
(1123785, 0, 1100417, 1123762),
(1123785, 0, 1101860, 1123760),
(1123785, 0, 1101863, 1123761),
(1123785, 0, 1117252, 1135702),
(1123785, 0, 0, 1135702),
(1123822, 0, 1100416, 1123826),
(1123822, 0, 1100417, 1123837),
(1123822, 0, 1101860, 1123841),
(1123822, 0, 1101863, 1123833),
(1123822, 0, 1117252, 1135703),
(1123822, 0, 0, 1135703),
(1123823, 0, 1100416, 1123827),
(1123823, 0, 1100417, 1123838),
(1123823, 0, 1101860, 1123842),
(1123823, 0, 1101863, 1123834),
(1123823, 0, 1117252, 1135704),
(1123823, 0, 0, 1135704),
(1123824, 0, 1100416, 1123828),
(1123824, 0, 1100417, 1123839),
(1123824, 0, 1101860, 1123843),
(1123824, 0, 1101863, 1123835),
(1123824, 0, 1117252, 1135705),
(1123824, 0, 0, 1135705),
(1123825, 0, 1100416, 1123829),
(1123825, 0, 1100417, 1123840),
(1123825, 0, 1101860, 1123844),
(1123825, 0, 1101863, 1123836),
(1123825, 0, 1117252, 1135706),
(1123825, 0, 0, 1135706),
(1119028, 0, 0, 1125228),
(1701521, 0, 0, 1701522);

DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((1701522, 'spell_ascension_reborn_summoners_armor_demon'), (1118800, 'spell_ascension_reborn_reign_of_dread'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1701522, 'spell_ascension_reborn_summoners_armor_demon'),
(1118800, 'spell_ascension_reborn_reign_of_dread');
