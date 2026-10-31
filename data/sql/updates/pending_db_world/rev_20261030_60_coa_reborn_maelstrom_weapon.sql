-- Reborn Maelstrom Weapon (talent 1151528-1151530) is a namesake of stock 51528, not a twin: three ranks that also
-- trigger the spell overlay 1153816, and a buff (1153817) that stacks to 8 and is consumed 5 at a time (1153822).
-- Without stock's rows the talent ranks proc at their Spell.dbc chance, 0, and never stack the buff. The ranks take
-- stock's proc row at 2, 4 and 6 procs per minute, as Freepick's three-rank talent; the buff takes stock 53817's
-- consume-on-cast row without charges, and its script removes the consumed stacks.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1151528, 1151529, 1151530, 1153817);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1151528, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 2, 0, 0, 0),
(1151529, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 4, 0, 0, 0),
(1151530, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 6, 0, 0, 0),
(1153817, 0, 11, 0x000001C3, 0x00008000, 0, 0, 0x0, 0x1, 0, 0x8, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 1153817 AND `ScriptName` = 'spell_ascension_reborn_maelstrom_weapon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1153817, 'spell_ascension_reborn_maelstrom_weapon');
