-- Storm Ascendance (#975): the learned spell 681110 only carries the magic damage done half. The transform and
-- the magic damage taken reduction its tooltip promises live in a second row, 681187, which the tooltip reaches
-- through the cross-spell token $681187s2 and which nothing in Spell.dbc, SQL or a module casts or links.
-- SPELL_LINK_AURA keeps the companion's lifetime tied to the cast, including the shared 15000 ms duration and
-- any duration modifier that applies to both rows.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 681110 AND `spell_effect` = 681187 AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(681110, 681187, 2, 'CoA Storm Ascendance: companion transform and magic damage taken reduction');

-- "In addition, your damaging spells now generate an additional 10 Static. Can only occur once every sec."
-- That clause is 681110's effect 0, an aura 42 proc triggering 804084 (Add 10 Static), but 681110's Spell.dbc
-- ProcFlags are 0, so no proc entry was generated and the aura could never proc. Admit the caster's own
-- damaging magic and none-damage-class casts on hit, with the authored one second internal cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = 681110;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(681110, 0, 0, 0, 0, 0, 69632, 1, 2, 0, 2, 0, 0, 100, 1000, 0);
