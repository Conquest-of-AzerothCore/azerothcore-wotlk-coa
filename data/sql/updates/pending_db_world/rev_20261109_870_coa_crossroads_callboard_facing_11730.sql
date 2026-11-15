-- The Warchief's Command Board in The Crossroads (guid 7905402) faces away from the plaza; turn it half a
-- circle, orientation 0.15995 -> 3.30154 with the matching rotation quaternion (#11730).
UPDATE `gameobject` SET `orientation` = 3.30154, `rotation2` = 0.996804, `rotation3` = -0.079890
WHERE `guid` = 7905402 AND `id` = 402001 AND `map` = 1
  AND `orientation` BETWEEN 0.15994 AND 0.15996;
