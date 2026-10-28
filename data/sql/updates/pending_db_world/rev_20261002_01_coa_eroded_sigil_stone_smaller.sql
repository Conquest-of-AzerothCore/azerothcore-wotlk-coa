-- Eroded Sigil Stone 254162 (the Worldforged pickup holding the Sigil of the Unmarked Mausoleum, one spawn in
-- Deathknell) towered over the players beside it (playtest); it shrinks by 60%.
UPDATE `gameobject_template` SET `size` = 0.4 WHERE `entry` = 254162;
