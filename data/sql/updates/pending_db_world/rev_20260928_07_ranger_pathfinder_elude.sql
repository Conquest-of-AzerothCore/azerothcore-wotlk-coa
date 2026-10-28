-- Ranger Pathfinder (706284): "Your Adrenaline Rush now incurs a 90% reduced cooldown when used while Elude is active."
-- The talent lowers effect 0 of the hidden Elude SLS3 record (524969), a cooldown modifier on Adrenaline Rush's family
-- flag, by 90 points; SLS3 must therefore be on the Ranger for exactly as long as Elude (801345) is.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 801345 AND `spell_effect` = 524969 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(801345, 524969, 2, 'Ranger Elude - Elude SLS3 (Pathfinder Adrenaline Rush cooldown)');
