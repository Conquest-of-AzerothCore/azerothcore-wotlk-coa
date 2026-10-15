-- Built from Ascension's combat logs and client data. Regenerate rather than edit by hand.
--
-- Onyxia in four difficulties, rebuilt from combat logs.
--
-- Attested: MapDifficulty.dbc has four rows for map 249, and the logs hold a
-- kill on every difficulty.
--
-- Assumed: the template ids. Onyxia pointed at 36538 "Onyxia (1)", which is
-- AzerothCore's own 25-player Onyxia and naming, not something found on
-- Ascension. For Mythic and Ascended there was nothing, and the core falls back
-- to Normal and Heroic, which would give Mythic less melee than Heroic. So the
-- convention attested for Molten Core applies here too: base + 100000 / 200000
-- / 300000, exact copies of the base. Health comes from flex and spell damage
-- from SpellDifficulty.dbc either way.

-- Undo. Not applied by the loader; run it by hand.
DELETE FROM `creature_template` WHERE `entry` IN (110184,210184,310184);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (110184,210184,310184);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (110184,210184,310184);
DELETE FROM `creature_template_resistance` WHERE `CreatureID` IN (110184,210184,310184);
DELETE FROM `creature_template_spell` WHERE `CreatureID` IN (110184,210184,310184);
DELETE FROM `creature_template_addon` WHERE `entry` IN (110184,210184,310184);
DELETE FROM `creature_onkill_reputation` WHERE `creature_id` IN (110184,210184,310184);
UPDATE `creature_template` SET `difficulty_entry_1` = 36538, `difficulty_entry_2` = 0,
    `difficulty_entry_3` = 0, `ScriptName` = 'boss_onyxia' WHERE `entry` = 10184;
UPDATE `creature` SET `spawnMask` = 3 WHERE `map` = 249;
UPDATE `gameobject` SET `spawnMask` = 3 WHERE `map` = 249;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_onyxia_coa_breath';
DELETE FROM `coa_boss_flex` WHERE `entry` = 10184;
