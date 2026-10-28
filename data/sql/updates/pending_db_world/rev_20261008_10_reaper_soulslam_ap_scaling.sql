--
-- Soulslam (504014) opened for 1 damage and 2 on a critical hit instead of the attack power scaled damage
-- its tooltip promises.
--
-- The client row for the ability already carries its own numbers: effect 1 is APPLY_AURA MOD_STUN (the
-- "horrifying them in place for 3 sec" part), effect 2 is SCHOOL_DAMAGE with EffectBasePoints 1 and
-- EffectDieSides 1, and every per level, per combo point and real points per level term is 0. The damage the
-- tooltip advertises is the ${$AP*0.342} token, so the coefficient belongs to the server side and there was
-- no `spell_bonus_data` entry for 504014 at all.
--
-- Without a row, Unit::SpellDamageBonusDone and Unit::SpellDamageBonusTaken skip the table entirely: the
-- coefficient stays 0, no attack power term is added, and a target takes the row's fixed 2 damage (2 on a
-- critical hit after the crit multiplier), which is what the report describes. With the row,
-- `bonus->ap_bonus > 0` adds int32(ap_bonus * ApCoeffMod * stack * GetTotalAttackPowerValue(BASE_ATTACK)) at
-- both ends of the calculation and reproduces the tooltip's own 0.342 coefficient for a melee attack power
-- ability.
--
-- direct_bonus and dot_bonus stay 0 because the tooltip has no spell power term, and ap_dot_bonus stays 0
-- because the damage is not periodic.
--
DELETE FROM `spell_bonus_data` WHERE `entry` = 504014;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(504014, 0, 0, 0.342, 0, 'Reaper Soulslam attack power scaling');
