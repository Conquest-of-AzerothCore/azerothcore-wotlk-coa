-- Gri'lek (15082): the tester's live video of 2026-11-04 shows 3.5 million health with 11 players, about 318,182
-- per player (user-approved 2026-11-04); Heroic, Mythic and Ascended keep the x1.44, x1.88 and x2.32 ladder.
UPDATE `coa_boss_flex` SET `hp_d0` = 318182, `hp_d1` = 458182, `hp_d2` = 598182, `hp_d3` = 738182,
    `comment` = 'ZG Gri\'lek: 3.5 million at 11 players in the tester\'s live video of 2026-11-04'
 WHERE `entry` = 15082;
