-- Ealdmaine Caverns (#11954, #12021): clicking Dead Ealdmaine Ealdir 164225 casts the Ealdir attire (365016 men,
-- 365017 women) and the Ealdmaine Neutral Reaction 365094. rev_20261108_9940 gave 365094 spell_area rows for Baile
-- Escada (area 10282 after 175117) and Telperion's cat form (aura 365046); a spell with area rows is refused
-- everywhere else, so at the corpse the reaction failed with "You are in the wrong zone." Allow it anywhere under the
-- Ealdir attire as well, which the same click applies first.
DELETE FROM `spell_area` WHERE `spell` = 365094 AND `area` = 0 AND `aura_spell` IN (365016, 365017);
INSERT INTO `spell_area` (`spell`, `area`, `quest_start`, `quest_end`, `aura_spell`, `racemask`, `gender`, `autocast`, `quest_start_status`, `quest_end_status`) VALUES
(365094, 0, 0, 0, 365016, 0, 2, 0, 64, 11),
(365094, 0, 0, 0, 365017, 0, 2, 0, 64, 11);
