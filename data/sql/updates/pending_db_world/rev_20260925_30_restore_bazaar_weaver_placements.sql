-- Restore Tiraxis to the capital Auction Houses and the sixteen Destiny Weaver placements.
-- Apply after rev_20260925_20_tiraxis_bazaar_gossip.sql, which removes additional Tiraxis spawns.
-- Tiraxis's seven new capital positions are based on nearby Auctioneer spawns.
-- The Weaver positions outside Durotar, Orgrimmar and Stormwind are reconstructed service
-- placements, not coordinates observed on the original realm. The Silvermoon and Azure Watch
-- positions use their actual innkeepers instead of the unrelated Outland innkeepers used before.

DELETE FROM `creature` WHERE `guid` BETWEEN 9000001 AND 9000008;
INSERT INTO `creature`
    (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`)
VALUES
    (9000001, 900007, 0, -8803.780, 670.239, 96.200, 4.712, 300, 'Tiraxis: Stormwind Auction House'),
    (9000002, 900007, 0, -4956.000, -909.000, 505.170, 4.700, 300, 'Tiraxis: Ironforge Auction House'),
    (9000003, 900007, 1, 9865.000, 2341.000, 1321.670, 4.700, 300, 'Tiraxis: Darnassus Auction House'),
    (9000004, 900007, 530, -4031.000, -11738.000, -151.810, 0.500, 300, 'Tiraxis: Exodar Auction House'),
    (9000005, 900007, 1, 1677.000, -4460.000, 20.391, 1.900, 300, 'Tiraxis: Orgrimmar Auction House'),
    (9000006, 900007, 0, 1586.000, 193.000, -56.790, 2.600, 300, 'Tiraxis: Undercity Auction House'),
    (9000007, 900007, 1, -1204.000, 103.000, 134.700, 3.000, 300, 'Tiraxis: Thunder Bluff Auction House'),
    (9000008, 900007, 530, 9655.000, -7147.000, 16.857, 3.200, 300, 'Tiraxis: Silvermoon Auction House');

DELETE FROM `creature` WHERE `guid` BETWEEN 9000011 AND 9000026;
INSERT INTO `creature`
    (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `Comment`)
VALUES
    (9000011, 449340, 1, -635.231, -4230.280, 38.135, 0.000, 300, 'Destiny Weaver: Tav''vin (Durotar)'),
    (9000012, 449350, 1, 1621.810, -4385.910, 12.5408, 1.10337, 300, 'Destiny Weaver: Tav''ral (Orgrimmar)'),
    (9000013, 449341, 530, 9560.680, -7225.800, 16.430, 2.210, 300,
     'Destiny Weaver: Magistrix Benjamin (Silvermoon City)'),
    (9000014, 449351, 530, 9688.100, -7359.600, 12.010, 4.490, 300,
     'Destiny Weaver: Magistrix Belanor (Falconwing Square)'),
    (9000015, 449342, 0, -4836.670, -853.090, 502.000, 4.870, 300, 'Destiny Weaver: Thrain Galewin (Ironforge)'),
    (9000016, 449352, 0, -5597.600, -527.200, 399.740, 2.130, 300, 'Destiny Weaver: Thrainnor Galestrom (Kharanos)'),
    (9000017, 449345, 1, 10131.900, 2228.790, 1328.810, 2.220, 300, 'Destiny Weaver: Elundra Moonsong (Darnassus)'),
    (9000018, 449355, 1, 9806.210, 986.610, 1313.980, 4.800, 300, 'Destiny Weaver: Elundrel Moonsinger (Dolanaar)'),
    (9000019, 449347, 0, -9458.660, 20.190, 57.050, 3.040, 300, 'Destiny Weaver: Galric Olim (Goldshire)'),
    (9000020, 449357, 0, -8818.580, 671.774, 95.425, 5.200, 300, 'Destiny Weaver: Galrin Olemar (Stormwind)'),
    (9000021, 449343, 0, 1638.000, 226.000, -43.020, 4.700, 300, 'Destiny Weaver: Veylae (Undercity)'),
    (9000022, 449353, 0, 2272.500, 248.000, 34.340, 2.000, 300, 'Destiny Weaver: Veylin (Brill)'),
    (9000023, 449344, 530, -3742.000, -11692.000, -105.770, 1.000, 300, 'Destiny Weaver: Saltheris Dawnborn (Exodar)'),
    (9000024, 449354, 530, -4133.430, -12465.000, 44.180, 4.000, 300,
     'Destiny Weaver: Salthoril Dawnspire (Azure Watch)'),
    (9000025, 449346, 1, 1630.500, -4433.000, 15.760, 1.600, 300, 'Destiny Weaver: Waerun Cliffwalker (Orgrimmar)'),
    (9000026, 449356, 1, 336.000, -4681.000, 16.540, 3.500, 300, 'Destiny Weaver: Waeric Cliffstrider (Razor Hill)');
