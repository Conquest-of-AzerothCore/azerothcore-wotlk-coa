-- Dire Maul / Maraudon fixes after ingame check (03.10.2026)
-- Illyanna Ravenoak's Immolation Trap (2100236) places Ascension's trap object 264875, which did not exist here:
-- same trap as the vanilla Immolation Trap V (164875)

INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`)
VALUES
(264875, 6, 3074, 'Immolation Trap', '', '', '', 1.0, 12, 0, 5, 14301, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

-- Tinkerer Gizlock's Goblin Dragon Gun keeps the direction it started in (CoADungeonBossSpells.cpp)
DELETE FROM `spell_script_names` WHERE `spell_id` = 21833;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (21833, 'spell_coa_fixed_facing_channel');

-- Every door in the vanilla dungeons opens instantly on click without a key (ingame wish 03.10.2026): lock removed.
-- Event objects that only look like doors stay as they are (Zul'Farrak troll cages, Uldaman keystone, wards,
-- force fields, Portal of Aku'Mai). Scripted doors keep their flags and still open only through their event.
UPDATE `gameobject_template` SET `Data1` = 0 WHERE `type` = 0 AND `entry` IN (13965, 16397, 16399, 16400, 17153, 17154, 18895, 18934, 18935, 18936, 18971, 18972, 90858, 97700, 101854, 104591, 104600, 124367, 124368, 124369, 124370, 141869, 142207, 157816, 157817, 157818, 157819, 157820, 161460, 170558, 170559, 170560, 170562, 170563, 170564, 170565, 170566, 170567, 170568, 170569, 170570, 170571, 170573, 170574, 170575, 170576, 170577, 174554, 174555, 174556, 174557, 174558, 174559, 174560, 174561, 174562, 174563, 174564, 174565, 174566, 175167, 175352, 175353, 175356, 175357, 175368, 175967, 175968, 176194, 177217, 177219, 177221, 179549, 179550);
UPDATE `gameobject_template_addon` SET `flags` = `flags` & ~2 WHERE `entry` IN (13965, 16397, 16399, 16400, 17153, 17154, 18895, 18934, 18935, 18936, 18971, 18972, 90858, 97700, 101854, 104591, 104600, 124367, 124368, 124369, 124370, 141869, 142207, 157816, 157817, 157818, 157819, 157820, 161460, 170558, 170559, 170560, 170562, 170563, 170564, 170565, 170566, 170567, 170568, 170569, 170570, 170571, 170573, 170574, 170575, 170576, 170577, 174554, 174555, 174556, 174557, 174558, 174559, 174560, 174561, 174562, 174563, 174564, 174565, 174566, 175167, 175352, 175353, 175356, 175357, 175368, 175967, 175968, 176194, 177217, 177219, 177221, 179549, 179550); -- 'Locked' flag: clicking gave 'Invalid target'

-- Divine Retribution (Veng, Timmy the Cruel): stores 25% of the boss damage on the target, then releases it
DELETE FROM `spell_script_names` WHERE `spell_id` = 680624 AND `ScriptName` = 'spell_coa_divine_retribution';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (680624, 'spell_coa_divine_retribution');
