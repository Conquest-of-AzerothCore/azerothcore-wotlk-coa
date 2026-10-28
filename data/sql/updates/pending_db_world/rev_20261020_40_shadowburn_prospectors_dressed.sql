-- Shadowburn Prospectors (Kerebor) wore a dwarf outfit preset whose chest look only textures the sleeves, so they showed
-- bare-chested. They use the dressed Dark Iron miner model (825) instead, without the preset.
DELETE FROM `creature_display_preset` WHERE `entry` = 164274;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 164274;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(164274, 0, 825, 1, 1, 0);
