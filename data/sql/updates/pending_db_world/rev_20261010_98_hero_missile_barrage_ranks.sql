-- Missile Barrage 44401 takes a flat 2.5 sec off the next Arcane Missiles channel and fires its missiles every 0.5 sec
-- instead of every 1 sec, so a 5 sec rank still fires five missiles. Heroes roll and train the low ranks too: the
-- 3 sec rank 1 kept 0.5 sec of channel and fired a single missile (#6879). For a Hero the reduction is half the
-- channel of the highest Arcane Missiles rank known, never more than 2.5 sec, so every rank keeps its missile count.
DELETE FROM `spell_script_names` WHERE `spell_id` = 44401 AND `ScriptName` = 'aura_hero_missile_barrage';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(44401, 'aura_hero_missile_barrage');
