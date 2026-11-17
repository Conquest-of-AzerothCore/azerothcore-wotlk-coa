-- The eight Incarnation: One With The Light caches (193918 to 193925) have no contents in VanityCollection, the
-- database or any script, so a bought cache only starts its cooldown (#12472). rev_20261023_03 already took them out
-- of the Vanity Store as not usable; Tiraxis stops offering them too. A rotation already running keeps its stock
-- until the next draw.
DELETE FROM `ethereal_bazaar_pool` WHERE `item` BETWEEN 193918 AND 193925;
