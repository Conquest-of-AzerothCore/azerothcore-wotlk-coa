-- #9146 pinned the Dalaran Crater Silk Drape pickup (guid 6901050) where it was reported but left the module's
-- second copy 6940272, 8 yd away, so two drapes stood there. Drop the extra copy (#10834).
DELETE FROM `gameobject` WHERE `guid` = 6940272 AND `id` = 95535 AND `map` = 0
  AND `position_x` BETWEEN 305.5 AND 306.1 AND `position_y` BETWEEN 166.9 AND 167.5;
