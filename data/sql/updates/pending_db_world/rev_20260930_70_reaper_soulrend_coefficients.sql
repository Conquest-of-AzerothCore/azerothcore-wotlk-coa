-- Soulrend reads ${$m1+0+$AP*.36+$sps*.297} on every rank, but it is a melee-class spell with EffectBonusMultiplier 0
-- and no bonus row, so Unit::SpellDamageBonusDone added neither attack power nor spell power: a rank 2 cast hit for its
-- 33-35 base while the tooltip showed 72. The 573316 row covers ranks 2-8 through the first-rank lookup; 802731 is a
-- standalone copy with the same tooltip. MaxLevel 0 keeps the spell level penalty out of the spell power term.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (573316, 802731);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(573316, 0.297, 0, 0.36, 0, 'Reaper - Soulrend'),
(802731, 0.297, 0, 0.36, 0, 'Reaper - Soulrend');
