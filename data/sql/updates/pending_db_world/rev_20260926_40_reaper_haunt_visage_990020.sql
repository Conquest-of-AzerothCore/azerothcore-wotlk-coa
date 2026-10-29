-- Haunt (573425) summons creature 990020 since the 2026-09-24 client patch (it summoned 840000 before). Realms that
-- carry the CoA world data already have 990020 ('Haunt', script npc_ascension_reaper_haunt); anywhere else it is
-- created from the 840000 visage it replaces, so the running-away visage works with either Spell.dbc. The visage
-- takes the caster's appearance through Clone Me!; a realm's own 990020 rows are left alone.
DROP TEMPORARY TABLE IF EXISTS `tmp_haunt_visage`;
CREATE TEMPORARY TABLE `tmp_haunt_visage` SELECT * FROM `creature_template`
WHERE `entry` = 840000 AND NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 990020);
UPDATE `tmp_haunt_visage` SET `entry` = 990020, `name` = 'Haunt', `ScriptName` = 'npc_ascension_reaper_haunt';
INSERT INTO `creature_template` SELECT * FROM `tmp_haunt_visage`
ON DUPLICATE KEY UPDATE `entry` = VALUES(`entry`);
DROP TEMPORARY TABLE `tmp_haunt_visage`;

DROP TEMPORARY TABLE IF EXISTS `tmp_haunt_visage_has_model`;
CREATE TEMPORARY TABLE `tmp_haunt_visage_has_model` SELECT `CreatureID`
FROM `creature_template_model` WHERE `CreatureID` = 990020;
DROP TEMPORARY TABLE IF EXISTS `tmp_haunt_visage_model`;
CREATE TEMPORARY TABLE `tmp_haunt_visage_model` SELECT * FROM `creature_template_model`
WHERE `CreatureID` = 840000 AND NOT EXISTS (SELECT 1 FROM `tmp_haunt_visage_has_model`);
UPDATE `tmp_haunt_visage_model` SET `CreatureID` = 990020;
DELETE FROM `creature_template_model`
WHERE `CreatureID` = 990020 AND NOT EXISTS (SELECT 1 FROM `tmp_haunt_visage_has_model`);
INSERT INTO `creature_template_model` SELECT * FROM `tmp_haunt_visage_model`;
DROP TEMPORARY TABLE `tmp_haunt_visage_model`;
DROP TEMPORARY TABLE `tmp_haunt_visage_has_model`;
