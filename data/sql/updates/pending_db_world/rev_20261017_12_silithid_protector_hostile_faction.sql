-- Egg Hunt (quest 868): the Silithid Protectors (3503) around the Silithid Mounds
-- show Neutral instead of Hostile. The template carries faction template 7,
-- whose masks are all zero (no hostility to players, no enemy factions), while
-- every other silithid at the same site (Creeper 3250, Grub 3251, Swarmer 3252)
-- uses faction template 413: hostile to players and an enemy of faction 309
-- "Scorpid". Stock data shipped the 7, so this is a data correction, not a
-- regression restore. No spawn script, C++ script, summon group, pool, event or
-- template/script override touches 3503 or the mound (3685), so the template
-- faction governs every spawn. Align the Protector with its neighbours.

UPDATE `creature_template` SET `faction` = 413 WHERE `entry` = 3503;
