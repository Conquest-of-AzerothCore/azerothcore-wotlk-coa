-- Freepick (Dawnrise) Death Knight tree: abilities match their tooltips.

-- Ascension's (SP+AP) formulas: the rows carried the attack power part only, and some ranks had no row at all.
-- Icy Touch "{361+(SP+AP)*0.1}" (ranks 2-6 no row); Howling Blast "{518+(AP+SP)*0.2}" (ranks 2-3 no row: rank 2 hit
-- 161 with +1000 AP); Blood Boil "{180+(AP+SP)*0.06}" (ranks 2-5 no row); Death and Decay "{62+(SP+AP)*0.0475}" per
-- tick on its damage spell 52212 (row 0.04805 AP only); Plague Strike's Blood Plague "{416+(AP+SP)*0.0632}" (55078:
-- AP only).
DELETE FROM `spell_bonus_data` WHERE `entry` IN (45477, 46507, 46508, 46509, 46510, 46511, 49896, 49903, 49904, 49909, 49184, 49253, 49254, 51409, 51410, 51411, 48721, 48884, 48885, 48886, 48887, 49939, 49940, 49941, 52212, 55078);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(45477, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(46507, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(46508, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(46509, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(46510, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(46511, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(49896, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(49903, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(49904, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(49909, 0.1, 0, 0.1, 0, 'Death Knight - Icy Touch'),
(49184, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(49253, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(49254, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(51409, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(51410, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(51411, 0.2, 0, 0.2, 0, 'Death Knight - Howling Blast'),
(48721, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(48884, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(48885, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(48886, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(48887, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(49939, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(49940, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(49941, 0.06, 0, 0.06, 0, 'Death Knight - Blood Boil'),
(52212, 0.0475, 0, 0.0475, 0, 'Death Knight - Death and Decay'),
(55078, 0, 0.06325, 0, 0.06325, 'Death Knight - Blood Plague');
