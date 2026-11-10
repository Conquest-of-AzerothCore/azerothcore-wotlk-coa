-- The portable Hero's Call Board (412000) and Warchief's Command Board (412001), summoned by items
-- 1913515/1913516, place and open their gossip menu (fixed by rev_20261028_61) but every category stayed
-- empty: HeroCallBoard.cpp's ShowCategory reads quests from gameobject_queststarter/gameobject_questender
-- keyed by the clicked entry, and neither portable entry had any row there, unlike the permanent boards
-- they mirror (402000 Hero's Call Board, 402001 Warchief's Command Board). #9948.
DELETE FROM `gameobject_queststarter` WHERE `id` IN (412000, 412001);
INSERT INTO `gameobject_queststarter` (`id`, `quest`)
SELECT 412000, `quest` FROM `gameobject_queststarter` WHERE `id` = 402000
UNION ALL
SELECT 412001, `quest` FROM `gameobject_queststarter` WHERE `id` = 402001;

DELETE FROM `gameobject_questender` WHERE `id` IN (412000, 412001);
INSERT INTO `gameobject_questender` (`id`, `quest`)
SELECT 412000, `quest` FROM `gameobject_questender` WHERE `id` = 402000
UNION ALL
SELECT 412001, `quest` FROM `gameobject_questender` WHERE `id` = 402001;
