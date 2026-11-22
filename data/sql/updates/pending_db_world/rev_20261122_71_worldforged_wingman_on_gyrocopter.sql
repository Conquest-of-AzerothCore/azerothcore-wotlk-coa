-- The Wingman (515801, guid 6942306) rests on the Tanaris gyrocopter's wing at the realm height 3.485 (AscensionDB
-- addon observation, catalogue d6494ceb3150 2026-09-12; Descension jealous_wf_pickups.sql). Batch 5 lowered it to
-- 2.6922, 0.7 yd under the wing, where the rifle model is buried in the doodad.
UPDATE `gameobject` SET `position_z` = 3.485 WHERE `guid` = 6942306 AND `id` = 515801;
