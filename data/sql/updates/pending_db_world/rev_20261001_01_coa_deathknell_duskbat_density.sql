-- Rude Awakening (363): the Duskbats on the crypt road to Deathknell were too dense, most of them over the road
-- itself (playtest). 15 of the 29 Duskbats between the crypt hill and the village are removed: every one within
-- 10.1 yd of the road (TIRISFALLSTONEROAD01 weight >= 0.5 in the client ADT; they wander 10 yd), then the next
-- two. 14 stay, the nearest 15.1 yd off the road; the quest needs 8.
DELETE FROM `creature` WHERE `id` = 1512 AND `guid` IN (41903, 9010100, 9010101, 9010102, 9010104, 9010106, 9010108,
    9010109, 9010110, 9010112, 9010114, 9010115, 9010119, 9010122, 9010103);
