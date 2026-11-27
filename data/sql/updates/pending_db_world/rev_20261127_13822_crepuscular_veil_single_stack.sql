-- Crepuscular Veil from every Shadow of Obsidius adds to one shared stack instead of replacing it (#13822)
DELETE FROM `spell_custom_attr` WHERE `spell_id` = 5011092;
INSERT INTO `spell_custom_attr` (`spell_id`, `attributes`) VALUES
(5011092, 4194304);
