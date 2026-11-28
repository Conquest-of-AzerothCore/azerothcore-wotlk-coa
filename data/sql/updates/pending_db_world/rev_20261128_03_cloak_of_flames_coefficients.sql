-- Cloak of Flames (3475): equip damage shield 909276 "Immolation" had no spell power or attack power coefficient
-- (no spell_bonus_data row, EffectBonusMultiplier 0). Tooltip: ${$m1+0.035*$SP+0.023*$AP} Fire damage.
DELETE FROM `spell_bonus_data` WHERE `entry` = 909276;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(909276, 0.035, 0, 0.023, 0, 'Cloak of Flames - Immolation');
