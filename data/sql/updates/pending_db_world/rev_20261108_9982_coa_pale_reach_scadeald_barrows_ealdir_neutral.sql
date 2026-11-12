-- The Ealdmaine Neutral Reaction (365094) that keeps the Baile Escada Ealdir neutral after The Ealdir of Baile
-- Escada (175117) held only inside Baile Escada (area 10282), so villagers standing in the surrounding Scadeald
-- Barrows (10255) showed hostile and turned neutral at the village edge. It now holds in the Barrows too.
DELETE FROM `spell_area` WHERE `spell` = 365094 AND `area` = 10255;
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`, `gender`, `autocast`, `quest_start_status`, `quest_end_status`) VALUES
(365094, 10255, 175117, 0, 0, 0, 2, 1, 64, 11);
