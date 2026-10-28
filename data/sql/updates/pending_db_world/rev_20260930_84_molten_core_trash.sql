-- Molten Core trash as CoA runs it (db.exil.es export, exiles-db-export-2026-09-13).
-- Four entries carry CoA's names; they already stand where CoA's do and fight the same role.
UPDATE `creature_template` SET `name` = 'Corvus the Nimble', `subname` = 'Hand of the Harbinger' WHERE `entry` IN (11662, 111662, 211662, 311662);
UPDATE `creature_template` SET `name` = 'Flamewaker Acolyte' WHERE `entry` IN (11663, 111663, 211663, 311663);
UPDATE `creature_template` SET `name` = 'Cindermaw' WHERE `entry` IN (11672, 111672, 211672, 311672);
UPDATE `creature_template` SET `name` = 'Lesser Son of Flame' WHERE `entry` IN (12143, 112143, 212143, 312143);
-- Lava Annihilator, Lava Elemental and Lava Reaver had no AI; CoA gives each a kit. The spells are CoA's,
-- the timers are designed after Firewalker and Flameguard (CoA records no cooldown for them).
UPDATE `creature_template` SET `AIName` = 'SmartAI' WHERE `entry` IN (11665, 111665, 211665, 311665, 12076, 112076, 212076, 312076, 12100, 112100, 212100, 312100);
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (11665, 12076, 12100) AND `source_type` = 0;
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `event_param5`, `event_param6`, `action_type`, `action_param1`, `action_param2`, `action_param3`, `action_param4`, `action_param5`, `action_param6`, `target_type`, `target_param1`, `target_param2`, `target_param3`, `target_param4`, `target_x`, `target_y`, `target_z`, `target_o`, `comment`) VALUES
(11665, 0, 0, 0, 0, 0, 100, 0, 8000, 12000, 12000, 15000, 0, 0, 11, 16168, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Annihilator - In Combat - Cast Flame Buffet'),
(11665, 0, 1, 0, 0, 0, 100, 0, 10000, 14000, 12000, 15000, 0, 0, 11, 22088, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Annihilator - In Combat - Cast Fireball'),
(11665, 0, 2, 0, 0, 0, 100, 0, 6000, 9000, 15000, 20000, 0, 0, 11, 2100148, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Annihilator - In Combat - Cast Crush Armor'),
(12076, 0, 0, 0, 0, 0, 100, 0, 9000, 13000, 13000, 16000, 0, 0, 11, 19641, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Elemental - In Combat - Cast Pyroclast Barrage'),
(12076, 0, 1, 0, 0, 0, 100, 0, 5000, 8000, 10000, 14000, 0, 0, 11, 2105026, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Elemental - In Combat - Cast Fireball Volley'),
(12100, 0, 0, 0, 0, 0, 100, 0, 8000, 12000, 10000, 14000, 0, 0, 11, 19644, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Reaver - In Combat - Cast Strike'),
(12100, 0, 1, 0, 0, 0, 100, 0, 5000, 7000, 8000, 11000, 0, 0, 11, 2100004, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 'Lava Reaver - In Combat - Cast Cleave');
