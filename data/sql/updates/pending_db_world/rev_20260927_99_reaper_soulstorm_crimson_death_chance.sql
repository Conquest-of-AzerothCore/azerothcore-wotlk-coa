-- rev_20260920_17 gave both rows Chance 100, but Soulstorm 705403 refunds a Reaped Soul on 40% of Requiem and
-- Soulrend hits and Crimson Death 705414 recasts Slaughter on 20% of casts. Crimson Death also needs the hit
-- phase, whose proc event carries Slaughter's target; the cast phase recast fails without one. Plain UPDATEs
-- keep this correct whichever order it runs in relative to other changes to these rows.
UPDATE `spell_proc` SET `Chance` = 40 WHERE `SpellId` = 705403;
UPDATE `spell_proc` SET `Chance` = 20, `SpellPhaseMask` = 2 WHERE `SpellId` = 705414;
