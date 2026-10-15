--
-- Journey to the Core (#2012): Tremor damage creates one delayed ground burst per proc.
DELETE FROM `spell_proc` WHERE `SpellId` IN (560510);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(560510, 0, 37, 64, 0, 0, 332116, 1, 2, 3, 2, 0, 0, 20, 0, 0);
SET @ScriptName = 'aura_ascension_journey_damage';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (560510) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560510, @ScriptName);
SET @ScriptName = 'spell_ascension_journey_ground';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (302534) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(302534, @ScriptName);
SET @ScriptName = 'aura_ascension_journey_ground';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (302534) AND `ScriptName` = @ScriptName;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(302534, @ScriptName);
DELETE FROM `spell_bonus_data` WHERE `entry` = 302590;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`)
VALUES (302590, 1, 0, 0, 0, 'Journey to the Core: Crag uses 100% Nature spell power');
