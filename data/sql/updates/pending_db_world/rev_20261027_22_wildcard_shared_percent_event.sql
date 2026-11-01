START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277785, 280375);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(277785, 16, 1, 2, 3, 2, 50),
(280375, 4, 0, 0, 3, 0, 100);
DELETE FROM `spell_bonus_data` WHERE `entry` IN (277787, 280376);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(277787, 0, 0, 0, 0, 'Twin Fang - percentage of triggering damage, no extra stat coefficient'),
(280376, 0, 0, 0, 0, 'Champion of the Sun - percentage of triggering damage, no extra stat coefficient');
COMMIT;
