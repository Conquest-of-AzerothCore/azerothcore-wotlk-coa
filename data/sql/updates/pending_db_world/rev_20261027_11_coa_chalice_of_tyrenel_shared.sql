-- Blessings of the Light (255114): the Chalice of Tyrenel (gameobject 255063) has a single spawn and the quest needs
-- one chalice, but the object was consumed by the first player who looted it, so everyone else on the quest waited
-- for its respawn. It now stays after looting, like the Pristine Black Dragon Egg (254685); only players on the quest
-- can open it and receive the chalice.
UPDATE `gameobject_template` SET `Data3` = 0 WHERE `entry` = 255063;
