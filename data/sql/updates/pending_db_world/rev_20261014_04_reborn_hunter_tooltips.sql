-- Warcraft Reborn Hunter: traps place working objects, and the hunter's damage, aspects and talents do what their
-- tooltips say.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
`Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(1164638, 6, 3074, 'Immolation Trap', '', '', '', 1, 12, 0, 5, 1113797, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164639, 6, 3073, 'Frost Trap', '', '', '', 1, 12, 0, 5, 1163487, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164839, 6, 3072, 'Explosive Trap', '', '', '', 1, 12, 0, 5, 1113812, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164872, 6, 3074, 'Immolation Trap II', '', '', '', 1, 12, 0, 5, 1114298, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164873, 6, 3074, 'Immolation Trap III', '', '', '', 1, 12, 0, 5, 1114299, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164874, 6, 3074, 'Immolation Trap IV', '', '', '', 1, 12, 0, 5, 1114300, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164875, 6, 3074, 'Immolation Trap V', '', '', '', 1, 12, 0, 5, 1114301, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164879, 6, 3072, 'Explosive Trap II', '', '', '', 1, 12, 0, 5, 1114314, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1164880, 6, 3072, 'Explosive Trap III', '', '', '', 1, 12, 0, 5, 1114315, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1181030, 6, 3074, 'Immolation Trap VI', '', '', '', 1, 12, 0, 5, 1127024, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1181031, 6, 3072, 'Explosive Trap IV', '', '', '', 1, 12, 0, 5, 1127026, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1183957, 6, 7205, 'Snake Trap', '', '', '', 1, 12, 0, 5, 1145145, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1189318, 6, 3074, 'Immolation Trap VII', '', '', '', 1, 12, 0, 5, 1149053, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1189319, 6, 3074, 'Immolation Trap VIII', '', '', '', 1, 12, 0, 5, 1149054, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1189321, 6, 3072, 'Explosive Trap V', '', '', '', 1, 12, 0, 5, 1149064, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340),
(1189322, 6, 3072, 'Explosive Trap VI', '', '', '', 1, 12, 0, 5, 1149065, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', '', 12340)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`), `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`), `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`), `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`), `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`), `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`), `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`), `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`), `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`), `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`), `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `gameobject_template_addon` WHERE `entry` IN (1164638, 1164872, 1164873, 1164874, 1164875, 1181030, 1189318, 1189319, 1164839, 1164879, 1164880, 1181031, 1189321, 1189322, 1164639, 1183957);
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`, `mingold`, `maxgold`, `artkit0`, `artkit1`, `artkit2`, `artkit3`) VALUES
(1164638, 0, 0, 0, 0, 0, 0, 0, 0),
(1164639, 0, 0, 0, 0, 0, 0, 0, 0),
(1164839, 0, 0, 0, 0, 0, 0, 0, 0),
(1164872, 0, 0, 0, 0, 0, 0, 0, 0),
(1164873, 0, 0, 0, 0, 0, 0, 0, 0),
(1164874, 0, 0, 0, 0, 0, 0, 0, 0),
(1164875, 0, 0, 0, 0, 0, 0, 0, 0),
(1164879, 0, 0, 0, 0, 0, 0, 0, 0),
(1164880, 0, 0, 0, 0, 0, 0, 0, 0),
(1181030, 0, 0, 0, 0, 0, 0, 0, 0),
(1181031, 0, 0, 0, 0, 0, 0, 0, 0),
(1183957, 0, 0, 0, 0, 0, 0, 0, 0),
(1189318, 0, 0, 0, 0, 0, 0, 0, 0),
(1189319, 0, 0, 0, 0, 0, 0, 0, 0),
(1189321, 0, 0, 0, 0, 0, 0, 0, 0),
(1189322, 0, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_bonus_data` WHERE `entry` IN (1101978, 1103674, 1121004);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1101978, 0, 0, 0, 0.04, 'Warcraft Reborn Hunter - Serpent Sting'),
(1103674, 0, 0, 0, 0.02, 'Warcraft Reborn Hunter - Black Arrow'),
(1121004, 0, 0, 0.195, 0, 'Warcraft Reborn Hunter - Quick Shot');

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (1161846, 1161847) AND `spell_effect` = 1161848;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(1161846, 1161848, 2, 'Warcraft Reborn Hunter - Aspect of the Dragonhawk dodge'),
(1161847, 1161848, 2, 'Warcraft Reborn Hunter - Aspect of the Dragonhawk dodge');

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1153234, 1153237, 1153238) AND `ScriptName` = 'spell_hun_piercing_shots';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1153234, 'spell_hun_piercing_shots'),
(1153237, 'spell_hun_piercing_shots'),
(1153238, 'spell_hun_piercing_shots');

DELETE FROM `spell_proc` WHERE `SpellId` IN (-1113165, -1161846, 1153234, 1153237, 1153238);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`,
`SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-1113165, 0, 0, 0, 0, 0, 64, 0, 2, 0, 0, 0, 0, 0, 0, 0),
(-1161846, 0, 0, 0, 0, 0, 64, 0, 2, 0, 0, 0, 0, 0, 0, 0),
(1153234, 0, 9, 131073, 8388609, 201326593, 0, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(1153237, 0, 9, 131073, 8388609, 201326593, 0, 1, 2, 2, 0, 0, 0, 0, 0, 0),
(1153238, 0, 9, 131073, 8388609, 201326593, 0, 1, 2, 2, 0, 0, 0, 0, 0, 0);
