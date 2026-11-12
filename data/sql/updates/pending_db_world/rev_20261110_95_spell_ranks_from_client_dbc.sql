-- Spell ranks now come from the client's SpellRank.dbc. Rows that named a spell which is no longer a first rank are
-- covered by its chain's first rank and are dropped:
-- Ice Armor (7302) continues the Frost Armor chain (168), whose `-168` proc row has the same values.
DELETE FROM `spell_proc` WHERE `SpellId` = -7302;
-- Execute 5309 is rank 2 of 5308, so `-5308` already attaches spell_warr_execute; a second row would run it twice.
DELETE FROM `spell_script_names` WHERE `spell_id` = 5309 AND `ScriptName` = 'spell_warr_execute';
-- Group membership is read from the first rank, so these later ranks keep their groups through it.
DELETE FROM `spell_group` WHERE (`id`, `spell_id`) IN
((1002, 25782), (1005, 25894), (1006, 25898), (1007, 25899), (1075, 21562), (1077, 27681), (1079, 21849),
(1080, 23028), (1098, 27683), (1133, 567237), (1210, 300887), (103955, 572816), (2100004, 707340), (2110001, 300887),
(2110001, 501330), (2110001, 501331), (2110001, 501332), (2110001, 501333), (2110001, 707678), (2110002, 707340),
(2110003, 707677), (2110004, 523484), (2110004, 523494), (2110004, 803656), (2110005, 561143));
