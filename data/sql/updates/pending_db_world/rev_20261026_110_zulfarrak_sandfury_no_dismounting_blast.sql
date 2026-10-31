-- Zul'Farrak: Sandfury Shadowcaster (5648) and Sandfury Shadowhunter (7246) no longer cast
-- Dismounting Blast (18396) on aggro. Ascension lists neither as a caster of 18396 (db.exil.es,
-- crawl 2026-08-29): 5648 casts Demon Skin, Shadow Bolt and Shadow Word: Pain, 7246 Hex and Shoot.
DELETE FROM `smart_scripts` WHERE `entryorguid` IN (5648, 7246) AND `source_type` = 0 AND `id` = 0 AND `action_type` = 11 AND `action_param1` = 18396;
