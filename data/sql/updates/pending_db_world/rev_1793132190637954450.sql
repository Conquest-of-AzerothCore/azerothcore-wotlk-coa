-- Carnage (803814) triggers Born in Blood (560521) when its owner lands a killing blow on a target that yields
-- experience or honor. The spell carries no proc flags, so nothing ever triggered it.
DELETE FROM `spell_proc` WHERE `SpellId` = 803814;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `Chance`) VALUES (803814, 2, 100);
