-- Coming into Demonhood (200022): both Skull of Kaz spawns (9301201) lay on top of the rocks above Grillok Morzog,
-- about 30 yd over the Valley of Trials floor, where a Demon Hunter on the quest could neither see nor reach them.
-- They now lie on the valley floor inside the quest's map area, a few yards from Grillok, as the Skull of L'ok lies
-- beside Flowzie in Shadowglen.
UPDATE `gameobject` SET `position_x` = -594, `position_y` = -4135, `position_z` = 46.26 WHERE `guid` = 7912302 AND `id` = 9301201;
UPDATE `gameobject` SET `position_x` = -596, `position_y` = -4145, `position_z` = 47.26 WHERE `guid` = 7912303 AND `id` = 9301201;
