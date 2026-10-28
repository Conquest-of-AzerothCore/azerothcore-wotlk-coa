-- Dreadnought rank chain: Strength of the Black Empire never transformed.
--
-- Talent 680557 promises that Dreadnought "sheds your mortal form, transforming
-- you into a void monstrosity". The delivery is the 680556 helper, enabled by
-- AscensionCultist Refresh only while the player holds 680557 and an aura of
-- ranked spell 567524 (Unit::GetAuraOfRankedSpell walks the spell_ranks chain).
-- Dreadnought's server ranks (567524 rank 1, 567548 rank 2, 567549 rank 3,
-- 567550 rank 4, 567551 rank 5, 567552 rank 6) were never chained, so the lookup
-- only ever matched the exact rank-1 aura while the talent requires level 40
-- (rank 4+): the helper never applied, no transform and no damage reduction.
-- The same missing chain also kept the rank-agnostic Named() consumers
-- (Contracts Dreadnought taken-reduction, Auras amounts, Highest/Reduce) pinned
-- to rank 1. creature_template 250043 (display 28844) already exists and the
-- Contracts override already retargets 680556 at load, so only the chain was
-- missing. DELETE+INSERT stays idempotent.
DELETE FROM `spell_ranks` WHERE `first_spell_id` = 567524 OR `spell_id` IN (567524, 567548, 567549, 567550, 567551, 567552);
INSERT INTO `spell_ranks` (`first_spell_id`, `spell_id`, `rank`) VALUES
(567524, 567524, 1),
(567524, 567548, 2),
(567524, 567549, 3),
(567524, 567550, 4),
(567524, 567551, 5),
(567524, 567552, 6);
