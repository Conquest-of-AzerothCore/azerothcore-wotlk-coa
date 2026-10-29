-- Warcraft Reborn Improved Water Shield (1116180, 1116196, 1116198; crossover 1316198 twins the top rank): the Reborn
-- ranks are built unlike the stock ones (proc flags, chance), so they took neither the stock script nor its proc mask
-- and did nothing. They get both: Healing Wave, Lesser Healing Wave, Chain Heal and Riptide criticals consume a Water
-- Shield orb's mana.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1116180, 1116196, 1116198) AND `ScriptName` = 'spell_sha_imp_water_shield';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1116180, 'spell_sha_imp_water_shield'),
(1116196, 'spell_sha_imp_water_shield'),
(1116198, 'spell_sha_imp_water_shield');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1116180, 1116196, 1116198);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT `s`.`id`, `p`.`SchoolMask`, `p`.`SpellFamilyName`, `p`.`SpellFamilyMask0`, `p`.`SpellFamilyMask1`, `p`.`SpellFamilyMask2`, `p`.`ProcFlags`, `p`.`SpellTypeMask`, `p`.`SpellPhaseMask`, `p`.`HitMask`, `p`.`AttributesMask`, `p`.`DisableEffectsMask`, `p`.`ProcsPerMinute`, `p`.`Chance`, `p`.`Cooldown`, `p`.`Charges`
FROM `spell_proc` `p` JOIN (SELECT 1116180 AS `id` UNION ALL SELECT 1116196 UNION ALL SELECT 1116198) `s` WHERE `p`.`SpellId` = -16180;
