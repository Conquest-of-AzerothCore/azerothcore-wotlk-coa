-- #6240: Portal: Blasted Lands 966370 (item 100576, Legion Pocket Portal) is two SPELL_EFFECT_TRANS_DOOR effects
-- placing gameobjects 100576 and 100575, and neither has a gameobject_template row, so
-- Spell::EffectTransmitted returns without placing anything.
--
-- Neither id is in the Exiles export (release exiles-db-export-2026-09-13, table `gameobject`), so the rows are
-- reconstructed from the stock pair that does the same job, 195141 and 195142 "Portal to Blasted Lands":
-- GAMEOBJECT_TYPE_SPELLCASTER, display 8948. Their use spells 65728 and 65729 carry a level 58 condition and teleport
-- to -11708.4, -3168, -5.07 on map 0; the client spell 966369 "Portal Effect: Blasted Lands" has the same
-- TELEPORT_UNITS to TARGET_DEST_DB shape without that condition, but no spell_target_position row, so it gets the
-- stock destination. 966370's description says it teleports group members who use it to the Dark Portal in Blasted
-- Lands, so both objects are party-only (Data2 = 1) and use 966369.
-- Every column is written, so an entry that already exists with other values is replaced as a whole row.
INSERT INTO `gameobject_template` (
    `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`,
    `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`,
    `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`,
    `VerifiedBuild`
) VALUES
(100575, 22, 8948, 'Portal to Blasted Lands', '', '', '', 1, 966369, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(100576, 22, 8948, 'Portal to Blasted Lands', '', '', '', 1, 966369, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, '', '', 0)
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `IconName` = VALUES(`IconName`), `castBarCaption` = VALUES(`castBarCaption`), `unk1` = VALUES(`unk1`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
    `Data3` = VALUES(`Data3`), `Data4` = VALUES(`Data4`), `Data5` = VALUES(`Data5`), `Data6` = VALUES(`Data6`),
    `Data7` = VALUES(`Data7`), `Data8` = VALUES(`Data8`), `Data9` = VALUES(`Data9`), `Data10` = VALUES(`Data10`),
    `Data11` = VALUES(`Data11`), `Data12` = VALUES(`Data12`), `Data13` = VALUES(`Data13`),
    `Data14` = VALUES(`Data14`), `Data15` = VALUES(`Data15`), `Data16` = VALUES(`Data16`),
    `Data17` = VALUES(`Data17`), `Data18` = VALUES(`Data18`), `Data19` = VALUES(`Data19`),
    `Data20` = VALUES(`Data20`), `Data21` = VALUES(`Data21`), `Data22` = VALUES(`Data22`),
    `Data23` = VALUES(`Data23`), `AIName` = VALUES(`AIName`), `ScriptName` = VALUES(`ScriptName`),
    `VerifiedBuild` = VALUES(`VerifiedBuild`);

DELETE FROM `spell_target_position` WHERE `ID` = 966369 AND `EffectIndex` = 0;
INSERT INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`) VALUES
(966369, 0, 0, -11708.4, -3168, -5.07, 3.35103);
