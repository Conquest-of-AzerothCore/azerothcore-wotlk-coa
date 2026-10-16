-- Lord Kazzak: on Ascension he was fought on his own map (882, Throne of the Doom Lord), reached through the
-- Shrine of Lord Kazzak (rev_20261015_10_kazzak_shrine). His open-world spawn in the Tainted Scar sat
-- 1.2 yd under the terrain (#7517); he moves to the throne, position measured in game.
UPDATE `creature` SET `map` = 882, `zoneId` = 10237, `areaId` = 10237, `spawnMask` = 15,
    `position_x` = -12628.159, `position_y` = -2319.3174, `position_z` = 51.659, `orientation` = 5.5566854
WHERE `guid` = 9780100 AND `id` = 12397;

-- 1.5 times his model size.
UPDATE `creature_template_model` SET `DisplayScale` = 1.5 WHERE `CreatureID` = 12397 AND `Idx` = 0;
