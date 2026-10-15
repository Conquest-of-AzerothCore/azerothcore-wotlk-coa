--
-- Night Hunter's Howl, Aortic Assault and seven Mortal Form abilities dealt or healed their base points only: the
-- attack power and spell power terms their tooltips advertise were never applied.
--
-- Every rank's client tooltip carries the coefficient as a description token, with no matching
-- EffectBonusMultiplier, so the coefficient belongs to the server side:
--   Night Hunter's Howl  ${$m1+0+$AP*0.285}                     (effect 0 SCHOOL_DAMAGE)
--   Aortic Assault       each strike ${$m1+0+$AP*0.12}            (strike 806502, effect 0 SCHOOL_DAMAGE)
--                        finale ${$806214m1+$806214ppl1+$AP*0.6}  (finale 806214, effect 0 SCHOOL_DAMAGE)
--   Veinburst            ${$m1+0+$AP*.25+$sps*0.85)}             (effect 0 SCHOOL_DAMAGE)
--   Crimson Tide         ($m1+0+$SP*.28) per tick                (effect 0 PERIODIC_DAMAGE)
--   Scarlet Delirium     ${$m2+0+$SP*0.15} every $t2 sec          (effect 1 PERIODIC_LEECH)
--   Vampiric Fang        ${$m1+0+$SP*0.34}                       (effect 0 SCHOOL_DAMAGE)
--   Dark Liturgy         ${$m1+0+$SP*0.35+$SPI*0.25}              (effect 0 HEAL)
--   Sanguine Mend        ${$m1+0+$SPI*0.25+$AP*.2+$SP*.58}        (effect 0 HEAL)
--
-- None of these spells had a `spell_bonus_data` entry, so Unit::SpellDamageBonusDone and
-- Unit::SpellHealingBonusDone added nothing. SpellMgr::GetSpellBonusData falls back to the first rank through
-- `spell_ranks`, which lists every rank of the seven ranked chains, so one row per chain covers all ranks.
-- Aortic Assault's damage comes from its strike and finale spells, which carry the rows. The Spirit terms of
-- Dark Liturgy and Sanguine Mend are added to the base value by bloodmage_vitality_scaling.
--
DELETE FROM `spell_bonus_data`
    WHERE `entry` IN (500124, 806502, 806214, 504260, 504282, 801074, 804726, 800781, 802310);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(500124, 0, 0, 0.285, 0, 'Bloodmage Night Hunter''s Howl attack power scaling'),
(806502, 0, 0, 0.12, 0, 'Bloodmage Aortic Assault strike attack power scaling'),
(806214, 0, 0, 0.6, 0, 'Bloodmage Aortic Assault finale attack power scaling'),
(504260, 0.85, 0, 0.25, 0, 'Bloodmage Veinburst attack power and spell power scaling'),
(504282, 0, 0.28, 0, 0, 'Bloodmage Crimson Tide spell power scaling per tick'),
(801074, 0, 0.15, 0, 0, 'Bloodmage Scarlet Delirium spell power scaling per tick'),
(804726, 0.34, 0, 0, 0, 'Bloodmage Vampiric Fang spell power scaling'),
(800781, 0.35, 0, 0, 0, 'Bloodmage Dark Liturgy healing power scaling'),
(802310, 0.58, 0, 0.2, 0, 'Bloodmage Sanguine Mend healing power and attack power scaling');
