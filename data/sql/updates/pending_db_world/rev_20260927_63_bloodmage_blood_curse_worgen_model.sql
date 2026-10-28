-- #1406: Blood Curse (562720) shapeshifts into SpellShapeshiftForm 57 "Cursed Form", which the client ships with
-- CreatureDisplayID 0, and it has no SPELL_AURA_TRANSFORM of its own, so the Bloodmage keeps the mortal model.
-- The appearance is authored in the hidden companion 563124 "Worgen Form Visual" (rank "SLS", family 26): a clone of
-- Blood Curse (Category 572, SpellVisual 2325, SpellFamilyFlags[1] 0x80000000) whose only effect is an infinite
-- SPELL_AURA_TRANSFORM to creature 56332 "Tank Worgen Form" (display 574, Creature\Worgen\Worgen.mdx), the same
-- creature Eternal Curse (800157) transforms into; rev_20260916_09 already provides its template. Nothing applied it.
-- Ride it on the form aura (type 2 = SPELL_LINK_AURA), as Accursed Form rides 562722, so the worgen model applies with
-- Blood Curse and drops with it.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 562720 AND `spell_effect` = 563124 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(562720, 563124, 2, 'CoA Blood Curse - worgen transform helper');
