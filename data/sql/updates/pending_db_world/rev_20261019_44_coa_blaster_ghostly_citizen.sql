-- CoA #7771: Egan's Blaster did nothing on Ghostly Citizens (10385). The Spectral
-- Citizen (10384) answers the blaster aura (17368) directly, but 10385 only answered
-- the periodic trigger (17372), so a zap that never ticked summoned no Freed Soul.
-- Mirror 10384's blaster rows onto 10385: SPELLHIT 17368 summons the Freed Soul
-- (17408) and the citizen despawns through the link. Full-block rewrite per SQL rules.
DELETE FROM `smart_scripts` WHERE `entryorguid` = 10385 AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(10385, 0, 0, 0, 25, 0, 100, 512, 0, 0, 0, 0, 0, 22, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Reset - Set Event Phase'),
(10385, 0, 1, 2, 22, 1, 100, 512, 17, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Bow - Store Target'),
(10385, 0, 2, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038500, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 3, 4, 22, 1, 100, 512, 34, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Dance - Store Target'),
(10385, 0, 4, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038501, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 5, 6, 22, 1, 100, 512, 58, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Kiss - Store Target'),
(10385, 0, 6, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038502, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 7, 8, 22, 1, 100, 512, 101, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Wave - Store Target'),
(10385, 0, 8, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038503, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 9, 10, 22, 1, 100, 512, 77, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Rude - Store Target'),
(10385, 0, 10, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038504, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 11, 12, 22, 1, 100, 512, 77, 0, 0, 0, 0, 64, 1, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received Rude - Store Target'),
(10385, 0, 12, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 80, 1038505, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Emote Received - Run Script'),
(10385, 0, 13, 0, 4, 0, 100, 512, 0, 0, 0, 0, 0, 22, 3, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Aggro - Set Event Phase'),
(10385, 0, 14, 0, 0, 0, 100, 0, 7000, 14000, 30000, 40000, 0, 11, 16336, 32, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - In Combat - Cast Haunting Phantoms'),
(10385, 0, 15, 0, 0, 0, 100, 0, 4000, 19000, 19000, 31000, 0, 11, 7068, 0, 0, 0, 0, 0, 5, 20, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - In Combat - Cast Veil of Shadow'),
(10385, 0, 16, 17, 8, 0, 100, 769, 17372, 0, 0, 0, 0, 11, 17408, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Spell Hit - Cast Summon Freed Soul'),
(10385, 0, 17, 0, 61, 0, 100, 512, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Spell Hit - Despawn'),
(10385, 0, 18, 0, 25, 0, 100, 512, 0, 0, 0, 0, 0, 11, 16331, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Reset - Cast Incorporeal Defense'),
(10385, 0, 19, 20, 8, 0, 100, 1, 17368, 0, 0, 0, 0, 11, 17408, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - On Blaster Aura Hit - Summon Freed Soul'),
(10385, 0, 20, 0, 61, 0, 100, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 'Ghostly Citizen - Linked - Despawn');
