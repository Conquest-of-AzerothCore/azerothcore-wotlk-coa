-- Legion Pocket Portal (100576, spell 966370) and the six Remote of Retreat items (800577-800582, spells 992030,
-- 992032, 992034, 992036, 992038, 992040) place a party portal with SPELL_EFFECT_TRANS_DOOR. None of the portal
-- objects had a gameobject_template row, so Spell::EffectTransmitted placed nothing and the items did nothing
-- (#6240). The portals cast a TARGET_DEST_DB teleport that had no spell_target_position row either.
--
-- Objects: captured client gameobject cache (hertigservices/ascension-data cachedata). 100575 and 100576 from the
-- conquest-of-azeroth capture; 600576-600581 identical in every mode that captured them (conquest-of-azeroth,
-- free-pick, season-10-freepick, season-10-wildcard, season-9, stress-test, warcraft-reborn). The portals are
-- type 22 (GAMEOBJECT_TYPE_SPELLCASTER): Data0 the teleport spell, Data1 0 charges (unlimited), Data2 1 party only,
-- Data3 1 usable mounted. 100575 is the Legion portal's visual (type 5). Displays 138009, 138010 and 1042710 exist
-- in the server and client GameObjectDisplayInfo.dbc.
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`, `Data0`, `Data1`, `Data2`, `Data3`)
VALUES
(100575, 5, 138010, 'Legion pocket portal', 0.33, 0, 0, 0, 0),
(100576, 22, 138009, 'Portal to Blasted Lands', 0.33, 966369, 0, 1, 1),
(600576, 22, 1042710, 'Portal to Molten Core', 0.2, 992031, 0, 1, 1),
(600577, 22, 1042710, 'Portal to Zul''Gurub', 0.2, 992033, 0, 1, 1),
(600578, 22, 1042710, 'Portal to Blackwing Lair', 0.2, 992035, 0, 1, 1),
(600579, 22, 1042710, 'Portal to Ahn''Qiraj', 0.2, 992037, 0, 1, 1),
(600580, 22, 1042710, 'Portal to Naxxramas', 0.2, 992039, 0, 1, 1),
(600581, 22, 1042710, 'Portal to Onyxia''s Lair', 0.2, 992041, 0, 1, 1)
ON DUPLICATE KEY UPDATE `type` = VALUES(`type`), `displayId` = VALUES(`displayId`), `name` = VALUES(`name`),
    `size` = VALUES(`size`), `Data0` = VALUES(`Data0`), `Data1` = VALUES(`Data1`), `Data2` = VALUES(`Data2`),
    `Data3` = VALUES(`Data3`);

-- Destinations: no capture records where these portals land. Each reuses a destination the server already has
-- for the same place: the Dark Portal arrival from Outland (areatrigger_teleport 4352) for Blasted Lands, and
-- Ascension's own Stone of Retreat spells for the raids: Blackrock Mountain (777025) for Molten Core and Blackwing
-- Lair, Zul'Gurub (777024), Gates of Ahn'Qiraj (777026), Onyxia's Lair (777027) and Naxxramas (Dragonblight)
-- (76885), the only Naxxramas entrance this server has.
DELETE FROM `spell_target_position` WHERE `ID` IN (966369, 992031, 992033, 992035, 992037, 992039, 992041);
INSERT INTO `spell_target_position`
    (`ID`, `EffectIndex`, `MapID`, `PositionX`, `PositionY`, `PositionZ`, `Orientation`, `VerifiedBuild`)
VALUES
(966369, 0, 0, -11877.7, -3204.49, -18.49, 0.23, 0),
(992031, 0, 0, -7494.94, -1123.49, 265.547, 0, 0),
(992033, 0, 0, -11916.7, -1215.72, 92.289, 0, 0),
(992035, 0, 0, -7494.94, -1123.49, 265.547, 0, 0),
(992037, 0, 1, -8216.06, 1536.36, 1.308, 0, 0),
(992039, 0, 571, 3668.72, -1262.46, 243.622, 0, 0),
(992041, 0, 1, -4708.27, -3727.64, 54.5589, 0, 0);
