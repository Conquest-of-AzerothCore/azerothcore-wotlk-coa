--
-- Grove Guardian (#568): each friendly healing tick gains 25% AP; each hostile damage tick gains 45% AP.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (505208, 504824);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(505208, 0, 0, 0, 0.25, 'Primalist: Grove Guardian - healing'),
(504824, 0, 0, 0, 0.45, 'Primalist: Grove Guardian - damage');
