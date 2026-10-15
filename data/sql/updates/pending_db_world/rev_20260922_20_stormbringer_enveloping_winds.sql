-- #483 Enveloping Winds. The raid armor clause is delivered natively by 707546 effect 1; only the
-- "casting Gale makes your Air Elemental cast Gale" clause is missing, because effect 0 is a bare
-- SPELL_AURA_DUMMY with ProcFlags = 0 and no script.
-- The proc entry selects Gale by its own identity (family 22, SpellFamilyFlags[0] = 0x4000 = 16384,
-- damage class magic) on the hit phase, and aura_ascension_enveloping_winds makes the pet repeat the
-- exact rank the Stormbringer cast. The existing spell_group 2000200 row for 707547 is untouched.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_enveloping_winds';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(707546, 'aura_ascension_enveloping_winds');
DELETE FROM `spell_proc` WHERE `SpellId` = 707546;
INSERT INTO `spell_proc` (`SpellId`, `SpellFamilyName`, `SpellFamilyMask0`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `Chance`) VALUES
(707546, 22, 16384, 65536, 1, 2, 3, 100);
