-- #11514: the Primalist Dreamway portals 809935-809938 place gameobjects 376296-376299, which had no template, and the
-- Dreamway teleports 804741-804744 (TARGET_DEST_DB) had no destination, so neither did anything. The object rows are
-- the live values (AscensionDB client captures, 2026-09-04 to 2026-09-07; Project Descension coa_gobs.sql, b18d7ee7):
-- party-only spellcasters casting the matching teleport. Approved by the maintainer on 2026-11-07.
-- Every column is written, so an entry that already exists with other values is replaced as a whole row.
INSERT INTO `gameobject_template` (
    `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, `Data0`, `Data1`, `Data2`,
    `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`, `Data11`, `Data12`, `Data13`, `Data14`,
    `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`, `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`,
    `VerifiedBuild`
) VALUES
(376296, 22, 1027772, 'Dreamway: Dream Bough', '', '', '', 1, 804743, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(376297, 22, 1027772, 'Dreamway: Bough Shadow', '', '', '', 1, 804744, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(376298, 22, 1027772, 'Dreamway: Twilight Grove', '', '', '', 1, 804742, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, '', '', 0),
(376299, 22, 1027772, 'Dreamway: Seradane', '', '', '', 1, 804741, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
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

-- Destinations: the stock game_tele rows Seradane 827, TwilightGrove 1247, DreamBough 298 and BoughShadow 150.
DELETE FROM `spell_target_position` WHERE `ID` IN (804741, 804742, 804743, 804744) AND `EffectIndex` = 0;
INSERT INTO `spell_target_position` (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`) VALUES
(804741, 0, 0, 799.721, -3995.68, 122.007, 3.77399),
(804742, 0, 0, -10384.3, -421.588, 63.6179, 3.23856),
(804743, 0, 1, -2944.13, 1891.22, 33.9487, 0.049356),
(804744, 0, 1, 3155.52, -3526.2, 130.635, 5.5267);
