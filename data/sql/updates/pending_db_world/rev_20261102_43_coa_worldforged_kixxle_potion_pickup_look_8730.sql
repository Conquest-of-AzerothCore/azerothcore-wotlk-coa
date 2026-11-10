-- Worldforged Kixxle's Experimental Potion (#8730): the LootCollector pickups 9900022 and 9900047 drop
-- Kixxle's Experimental Potion (354149) and its recipe (354150) but carried the names and look of
-- unrelated objects. Name them after their items; the potion takes the bottle model 1058753 that
-- Ascension's own record gives its namesake object 254236. The recipe keeps its book model.
UPDATE `gameobject_template` SET `name` = 'Kixxle''s Experimental Potion', `displayId` = 1058753
WHERE `entry` = 9900022 AND `name` = 'Bundle of Dried Corn' AND `displayId` = 1034271;
UPDATE `gameobject_template` SET `name` = 'Recipe: Kixxle''s Experimental Potion'
WHERE `entry` = 9900047 AND `name` = 'Leatherworking Book' AND `displayId` = 6930;
