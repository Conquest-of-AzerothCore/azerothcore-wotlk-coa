-- Snowgrave's arena has icicles hanging from its ceiling; his Massive Stomp brings down the ones over the players,
-- and they stay down for the rest of the fight.
DELETE FROM `gameobject_template` WHERE `entry` = 978099;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`,
    `size`, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES
(978099, 5, 8324, 'Hanging Icicle', '', '', '', 0.5, '', '', 12340);
