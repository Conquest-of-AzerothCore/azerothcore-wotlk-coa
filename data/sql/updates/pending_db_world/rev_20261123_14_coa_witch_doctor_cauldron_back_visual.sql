-- Witch Doctor Brewing: a Witch Doctor with Cauldron Brewer (92085) carries a cauldron of green brew on their back
-- (SLiMOFI's Witch Doctor guide, uyoh-Txzd98 0:05, 2026-08-20). The client's Cauldron spells "Equip a visual cauldron
-- on your back"; 561287 draws spells\fx_youareanalchemist_aura.m2 upright on the back attachment, as in the video.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 92085 AND `spell_effect` = 561287 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(92085, 561287, 2, 'Cauldron Brewer - Cauldron (visual cauldron on the back)');
