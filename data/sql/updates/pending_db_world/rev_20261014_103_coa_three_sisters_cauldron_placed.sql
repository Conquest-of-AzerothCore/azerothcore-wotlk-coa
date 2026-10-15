-- The user placed the Three Sisters' cauldron with the stock Fel Cauldron (a lootable chest): that spawn becomes the quest
-- cauldron "The Three Sisters", which keeps the fel cauldron's look. The Cauldron Prop beside it stays as scenery.
UPDATE `gameobject_template` SET `displayId` = 7410, `size` = 1 WHERE `entry` = 2300801;
UPDATE `gameobject` SET `id` = 2300801 WHERE `guid` = 9920684 AND `id` = 517233;
