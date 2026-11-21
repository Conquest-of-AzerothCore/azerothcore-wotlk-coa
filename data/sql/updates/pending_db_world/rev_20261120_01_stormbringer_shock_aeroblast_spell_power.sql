-- Shock (804020, 503326-503332, 504634) reads ${$m1+0+$spn*0.55} (the higher of Arcane and Nature spell
-- power) and Aeroblast (801839) reads ${$m1+0+$spn*0.635}. Neither had a spell_bonus_data row and their
-- client coefficient is 0 or cleared at load, so they gained nothing from spell power and Master
-- Elementalist (705662) had no coefficient to raise.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (804020, 503326, 503327, 503328, 503329, 503330, 503331, 503332,
    504634, 801839);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(804020, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503326, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503327, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503328, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503329, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503330, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503331, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(503332, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(504634, 0.55, 0, 0, 0, 'Stormbringer Shock - SP'),
(801839, 0.635, 0, 0, 0, 'Stormbringer Aeroblast - SP');
