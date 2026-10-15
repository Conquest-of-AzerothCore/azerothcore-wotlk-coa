-- Ghastly Form's shield, which absorbed a tenth of what it promises.
--
-- 704357 says the shield absorbs ${$704358m1+$704358ppl1+$AP*.2}. The record behind it,
-- 704358, is one SPELL_AURA_SCHOOL_ABSORB with base 29 and 0.75 per level: at level 80 that
-- is about 150, and the attack power third of the sum - the part that makes it 1352 on a
-- geared Reaper - has nowhere to live in a DBC record. So the aura landed at 149 while its
-- own tooltip read 1352.
--
-- aura_ascension_reaper_ghastly_form adds the attack power term at DoEffectCalcAmount, the
-- same way Jailer's Bargain computes its percentage of maximum health.

DELETE FROM `spell_script_names` WHERE `spell_id` = 704358
  AND `ScriptName` = 'aura_ascension_reaper_ghastly_form';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(704358, 'aura_ascension_reaper_ghastly_form');
