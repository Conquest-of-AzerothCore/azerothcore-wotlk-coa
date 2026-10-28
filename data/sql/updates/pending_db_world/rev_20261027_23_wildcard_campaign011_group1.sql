START TRANSACTION;
DELETE FROM `spell_proc` WHERE `SpellId` IN (277082, 280220);
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`) VALUES
(277082, 16, 1, 2, 3, 2, 15),
(280220, 262144, 1, 2, 3, 2, 30);
DELETE FROM `spell_bonus_data` WHERE `entry` IN (277083, 280221);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(277083, 0, 0, 0, 0, 'Electrical Discharge - triggering damage percentage per native tick'),
(280221, 0, 0, 0, 0, 'Shadowcrawl - percentage of triggering periodic damage');
COMMIT;
