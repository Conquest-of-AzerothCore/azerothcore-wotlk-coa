START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` = 289261;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `Chance`) VALUES
(289261, 332116, 1, 2, 3, 2, 2, 100);
DELETE FROM `spell_bonus_data` WHERE `entry` = 289262;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(289262, 0, 0, 0, 0, 'Vampiric Tonic - native physical-damage percentage heal');
COMMIT;
