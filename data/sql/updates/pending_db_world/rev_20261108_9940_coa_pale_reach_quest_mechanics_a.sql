-- The Ealdir of Baile Escada (175117, #9827): the camp attacked Telperion's cat form (365046), whose FORCE_REACTION
-- effect is blank in Spell.dbc. The cat form now carries the Ealdmaine neutral reaction 365094 (faction 1373), and the
-- villagers use the Ealdir faction template 1373, which stays hostile outside the cat form.
UPDATE `creature_template` SET `faction` = 1373 WHERE `entry` BETWEEN 164348 AND 164354 AND `faction` = 14;
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 365046 AND `spell_effect` = 365094;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(365046, 365094, 2, 'Telperion''s cat form - Ealdir neutral reaction');

-- Handing the quest in to Deirdre ends the cat form (Wo-WScrn-Shot-071226-081937: the portrait is the player again),
-- and Baile Escada stays neutral afterwards (082233: the player walks the village uncloaked beside a yellow-named
-- Mindra Roble): the realm's Ealdmaine Neutral Reaction 365094 holds in Baile Escada (area 10282) once 175117 is done.
-- A spell with area rows is refused everywhere else, so a second row allows it anywhere under the cat form.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 164355 AND `source_type` = 0 AND `id` IN (10, 11);
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(164355, 0, 10, 11, 20, 0, 100, 0, 175117, 0, 0, 0, 0, 0, 28, 365046, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Deirdre - On The Ealdir of Baile Escada rewarded - Remove the cat form'),
(164355, 0, 11, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 0, 75, 365094, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 'Deirdre - Linked - Add Ealdmaine Neutral Reaction');
DELETE FROM `spell_area` WHERE `spell` = 365094 AND `area` IN (0, 10282);
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`, `gender`, `autocast`, `quest_start_status`, `quest_end_status`) VALUES
(365094, 10282, 175117, 0, 0, 0, 2, 1, 64, 11),
(365094, 0, 0, 0, 365046, 0, 2, 0, 64, 11);

-- Braicag Heights Watchtower (175113, #10691): nothing happened at the tower. On the realm (fppvzzEmIX8 7:56) the
-- thrown charge leaves the realm's Dynamite object 2300685 (a lit bundle, 10el_explorersleague_dynamite02) on the
-- floor, which goes off 5 s later; the tower then burns. The realm also shows a round red countdown over the charge
-- point (7:56.7); its source is not identified and it is not reproduced. The realm's helper 164528 plays Visual:
-- Explosion 365049 when it goes off and sets sixteen Stratholme building fires (StratholmeFireSmokeEmberM) on the
-- corners and roof of Gh_Trappertower_Alliance_01 for a minute; it stays until they go out, since its objects vanish
-- with it. The credit stays immediate.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data8`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(2300685, 8, 659539, 'Dynamite', '', '', '', 1.5, 18, 50, 0, 0, 0, 0, 0, '', '', 0),
(2399010, 5, 4452, 'Watchtower Fire', '', '', '', 2.5, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `size` = VALUES(`size`),
`Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`);
UPDATE `creature_template` SET `unit_flags` = 33554432, `flags_extra` = 130, `AIName` = 'SmartAI' WHERE `entry` = 164528;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 11686, `DisplayScale` = 1 WHERE `CreatureID` = 164528 AND `Idx` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (164528, 164529) AND `source_type` = 0;
DELETE FROM `smart_scripts` WHERE `entryorguid` = 2399001 AND `source_type` = 1 AND `id` BETWEEN 1 AND 12;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(2399001, 1, 1, 0, 8, 0, 100, 0, 365045, 0, 0, 0, 0, 0, 12, 164528, 3, 65000, 0, 0, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Braicag Heights Watchtower Charge Point - On Throw Dynamite hit - Summon personal explosion helper'),
(2399001, 1, 2, 0, 8, 0, 100, 0, 365045, 0, 0, 0, 0, 0, 50, 2300685, 5, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 'Braicag Heights Watchtower Charge Point - On Throw Dynamite hit - Place the dynamite for 5 s'),
(164528, 0, 0, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 11, 365049, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Cast Visual: Explosion'),
(164528, 0, 2, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, 6.5, 0.5, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 3, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, -6.5, 0.5, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 4, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, 6.5, 0.5, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 5, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, -6.5, 0.5, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 6, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, 6.5, 12, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 7, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, -6.5, 12, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 8, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, 6.5, 12, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 9, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, -6.5, 12, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 10, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, 6.5, 24, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 11, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 6.5, -6.5, 24, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 12, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, 6.5, 24, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 13, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -6.5, -6.5, 24, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 14, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 5, 0, 33.8, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 15, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, -5, 0, 33.8, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 16, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 5, 33.8, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute'),
(164528, 0, 17, 0, 1, 0, 100, 0, 5000, 5000, 0, 0, 0, 0, 50, 2399010, 60, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -5, 33.8, 0, '[TG] watchtower_dynamite_charge - After 5 seconds - Set the tower on fire for 1 minute');
UPDATE `smart_scripts` SET `event_flags` = 1
WHERE `entryorguid` = 164528 AND `source_type` = 0 AND (`id` = 0 OR `id` BETWEEN 2 AND 17);
