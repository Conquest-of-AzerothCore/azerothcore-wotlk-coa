-- Malgorm Hollowhoof becomes a fight (npc_coa_malgorm_hollowhoof in src/server/coa/AscensionThreeTotems.cpp) in place
-- of calling the village to arms. Players who ran it on CoA recall a charge at least every 20 seconds: a red line on
-- the floor and the ground quaking under him as he wound up, then a run until he struck a wall that killed the players
-- in his path outright and knocked them back; an enrage at half health for 10 seconds; Thunderclap; and Slam. CoA's
-- Charge 256743-256746 and Enrage 256756 build it, with the low-level creature Thunderclap 8078 every 14-18 s and
-- Slam 11430 (a 2 s stun) every 10-14 s;
-- spell_coa_malgorm_trample makes each trample 256745 lethal. A video of the fight shows him at 874 health at level 7
-- (health modifier 6.38 on the level 7 warrior base of 137). His aggro, kill and death lines are CoA's, as players
-- recorded them; the charge, enrage and low-health lines, the line visual 255356, the Ground Tremor 64228 quake and
-- the 30 yd reach are INFERRED.
-- In the Grimtotem Disguise he stands neutral instead of hostile: his faction is template 1842 (faction 1027, used by
-- no creature), hostile to players, and spell_coa_grimtotem_disguise forces it neutral while the disguise lasts.
UPDATE `creature_template` SET `AIName` = '', `ScriptName` = 'npc_coa_malgorm_hollowhoof', `faction` = 1842,
    `HealthModifier` = 6.38 WHERE `entry` = 161816;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 161816 AND `source_type` = 0;

DELETE FROM `spell_script_names` WHERE `spell_id` IN (256709, 256710, 256745);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(256709, 'spell_coa_grimtotem_disguise'),
(256710, 'spell_coa_grimtotem_disguise'),
(256745, 'spell_coa_malgorm_trample');

DELETE FROM `creature_text` WHERE `CreatureID` = 161816;
INSERT INTO `creature_text` (`CreatureID`, `GroupID`, `ID`, `Text`, `Type`, `Probability`, `comment`) VALUES
(161816, 0, 0, 'Ah... ha! You must be my daughter''s doing. I knew she wouldn''t sit idle. Very well, let''s see what you''re made of.', 14, 100, 'Malgorm - aggro (CoA)'),
(161816, 1, 0, 'Kneel, as the rebels knelt!', 14, 100, 'Malgorm - charge'),
(161816, 2, 0, 'Morriga thought steel could unseat me too. Ask her mate how that ended.', 14, 100, 'Malgorm - enrage'),
(161816, 3, 0, 'I spared my daughter once. I will not spare you!', 14, 100, 'Malgorm - low health'),
(161816, 4, 0, 'My daughter''s champion falls short of her designs. Desperation drives her, surely.', 12, 100, 'Malgorm - kills a player (CoA)'),
(161816, 5, 0, 'Ha... ngh...! You''ll see... now that she''s had her way... she''ll show you her true face...', 12, 100, 'Malgorm - death (CoA)');
