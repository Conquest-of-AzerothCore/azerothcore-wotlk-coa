-- The Sepulcher, Silverpine Forest (#10677): CoA AreaTrigger.dbc row 5850 (map 0, 425.51, 1621.24, 139.319, radius 25)
-- covers the upper inn, but the server had neither an areatrigger row nor a tavern row for it, so the client's trigger
-- packet was dropped and resting never started there. The row below copies the DBC record; faction 4 (Horde) copies
-- the stock Sepulcher tavern row 720.
DELETE FROM `areatrigger` WHERE `entry` = 5850;
INSERT INTO `areatrigger` (`entry`, `map`, `x`, `y`, `z`, `radius`, `length`, `width`, `height`, `orientation`) VALUES
(5850, 0, 425.51, 1621.24, 139.319, 25, 0, 0, 0, 0);

DELETE FROM `areatrigger_tavern` WHERE `id` = 5850;
INSERT INTO `areatrigger_tavern` (`id`, `name`, `faction`) VALUES
(5850, 'Silverpine Forest - The Sepulcher - Inn', 4);
