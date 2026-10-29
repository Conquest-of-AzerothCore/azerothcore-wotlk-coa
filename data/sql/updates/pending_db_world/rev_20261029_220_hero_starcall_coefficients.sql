-- Hero Starcall 289250 (#6990): the tooltip promises ${$m1+$spa*0.3+$AP*0.15} Arcane damage, but no coefficient row
-- existed, so the hit dealt only its base points.
DELETE FROM `spell_bonus_data` WHERE `entry` = 289250;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(289250, 0.3, 0, 0.15, 0, 'Hero Starcall - tooltip spell power and attack power');
