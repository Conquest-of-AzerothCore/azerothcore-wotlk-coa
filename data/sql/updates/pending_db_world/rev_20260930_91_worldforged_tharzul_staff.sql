-- Thar'zul's Staff (Burning Steppes, the Blood Crucible) lay 13 yd south of the blood barrier on the ritual
-- platform. It now lies at the centre of that barrier: the ADT doodad 8FX_NAZMIR_BLOODTROLL_BLOODBARRIER.M2
-- at (-7797.84, -633.93). z keeps the spawn's 1.86 yd above its floor: the platform floor there is 206.356
-- (6Oc_Bleedinghollow_Ritualcircle_Medium.wmo), so 208.213. Rotation unchanged.
UPDATE `gameobject` SET `position_x` = -7797.84, `position_y` = -633.93, `position_z` = 208.213
    WHERE `guid` = 6940157 AND `id` = 254664;
