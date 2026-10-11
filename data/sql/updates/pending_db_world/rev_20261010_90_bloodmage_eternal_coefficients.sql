--
-- Ravenous Strike (500123), Claw Sweep (500169), Bloodfang Bite (800156) and Rotclaw (804197) hit for their
-- base points only: the attack power and spell power terms their tooltips advertise were never applied.
--
-- Every rank's client tooltip carries the coefficient as a description token, with no matching
-- EffectBonusMultiplier, so the coefficient belongs to the server side:
--   Ravenous Strike  ${$m1+0+$AP*0.2+$SP*.2}           (effect 0 HEALTH_LEECH)
--   Claw Sweep       ${$m1+0+$AP*.2+$SP*0.2}           (effect 0 SCHOOL_DAMAGE)
--   Bloodfang Bite   ${$m1+0+$AP*0.265+$SP*.265}       (effect 0 SCHOOL_DAMAGE)
--   Rotclaw          ${$m1+$AP*0.11}, bleed ($m2+$AP*0.04) per tick (effect 0 SCHOOL_DAMAGE, effect 1 PERIODIC_DAMAGE)
--
-- None of the four chains had a `spell_bonus_data` entry, so Unit::SpellDamageBonusDone added neither term.
-- SpellMgr::GetSpellBonusData falls back to the first rank through `spell_ranks`, which lists every rank of
-- these chains, so one row per chain covers all ranks. direct_bonus is the spell power coefficient, ap_bonus the
-- direct attack power coefficient and ap_dot_bonus the attack power coefficient of each Rotclaw bleed tick.
--
DELETE FROM `spell_bonus_data` WHERE `entry` IN (500123, 500169, 800156, 804197);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(500123, 0.2, 0, 0.2, 0, 'Bloodmage Ravenous Strike attack power and spell power scaling'),
(500169, 0.2, 0, 0.2, 0, 'Bloodmage Claw Sweep attack power and spell power scaling'),
(800156, 0.265, 0, 0.265, 0, 'Bloodmage Bloodfang Bite attack power and spell power scaling'),
(804197, 0, 0, 0.11, 0.04, 'Bloodmage Rotclaw attack power scaling');
