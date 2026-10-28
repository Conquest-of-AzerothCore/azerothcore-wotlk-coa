-- Adventurer Mode Random Aggro (888071), periodically triggered by every Adventure Mode difficulty aura, pulled
-- every creature within 25 yards into combat. Adventure Mode's rules never mention it (#9031).
DELETE FROM `disables` WHERE `sourceType` = 0 AND `entry` = 888071;
INSERT INTO `disables` (`sourceType`, `entry`, `flags`, `params_0`, `params_1`, `comment`) VALUES
(0, 888071, 7, '', '', 'Adventurer Mode Random Aggro: no periodic aggro pulse in Adventure Mode');
