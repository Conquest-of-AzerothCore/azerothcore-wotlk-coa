-- Infinite Keeper (#829): "Using Unmake on an enemy affected by your Timerend now causes the enemy to erupt in a
-- vortex of sand, dealing ${$806313m1+$806313ppl1)$SP*0.12} Chromatic Damage every $806313t1 sec". The vortex is
-- 806313, a SPELL_AURA_PERIODIC_DAMAGE persistent area aura whose EffectBonusMultiplier is 0.0 and which had no
-- spell_bonus_data row, so its ticks carried no spell power term. The per-tick coefficient is the tooltip's 0.12.
START TRANSACTION;
DELETE FROM `spell_bonus_data` WHERE `entry` = 806313;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(806313, 0, 0.12, 0, 0, 'Local Chronomancer: Infinite Keeper - vortex tick, spell power term from its description');
COMMIT;
