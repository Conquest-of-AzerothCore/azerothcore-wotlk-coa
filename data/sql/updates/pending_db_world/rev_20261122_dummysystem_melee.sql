-- Melee systems the dummy-effect fixes were missing (tools/dummy_census/SYSTEMS-BRIEF.md): Swashbuckling, Demolish,
-- Forbidden Technique / Forbidden Dance, Power Loop. Scripts in src/server/coa/AscensionDummySystemMelee.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_dummysystem_melee_swashbuckling',
    'spell_dummysystem_melee_demolish', 'spell_dummysystem_melee_demolished_riposte',
    'spell_dummysystem_melee_forbidden_technique', 'spell_dummysystem_melee_shadow_return',
    'spell_dummysystem_melee_forbidden_dance', 'spell_dummysystem_melee_meditate',
    'spell_dummysystem_melee_meditate_chants', 'spell_dummysystem_melee_power_loop',
    'spell_dummysystem_melee_power_loop_maelstrom');
DELETE FROM `spell_script_names` WHERE `spell_id` = 954092 AND `ScriptName` = 'spell_dummyfix_warrior_demolish';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Swashbuckling passives: the buff holds while Swashbuckling (Bloodsail Captain: also in Defensive Stance; its
-- Mocking Blow grants En Garde!)
(277049, 'spell_dummysystem_melee_swashbuckling'),  -- En Garde! -> 277060
(281944, 'spell_dummysystem_melee_swashbuckling'),  -- Swashbuckler: Shocktrooper -> 281945
(81415, 'spell_dummysystem_melee_swashbuckling'),   -- Swashbuckler: Shocktrooper (enchant) -> 81416
(997127, 'spell_dummysystem_melee_swashbuckling'),  -- Swashbuckler: Bloodsail Captain -> 300110, Mocking Blow -> 92785
-- Demolish: stacks on melee critical hits taken; the critical hit at 6 stacks consumes them and empowers
(954092, 'spell_dummysystem_melee_demolish'),       -- Demolishing Strike's Demolish
(273795, 'spell_dummysystem_melee_demolish'),       -- Demolisher (talent)'s Demolish
-- Riposte while empowered by Demolish: Demolished Arms (954091)
(14251, 'spell_dummysystem_melee_demolished_riposte'),
(1114251, 'spell_dummysystem_melee_demolished_riposte'),
(1214251, 'spell_dummysystem_melee_demolished_riposte'),
(1464251, 'spell_dummysystem_melee_demolished_riposte'),
-- Forbidden Technique: Forbidden Dance grant; the ending dance takes the rogue back into its Shadow
(271981, 'spell_dummysystem_melee_forbidden_technique'),
(954327, 'spell_dummysystem_melee_forbidden_technique'),
(271999, 'spell_dummysystem_melee_shadow_return'),  -- Shadow Dance (Forbidden Technique)
(986233, 'spell_dummysystem_melee_shadow_return'),  -- Forbidden Dance (enchant)
-- Forbidden Dance: Ambush makes the Shadow throw a dagger
(271985, 'spell_dummysystem_melee_forbidden_dance'),
(1569658, 'spell_dummysystem_melee_forbidden_dance'),
(986233, 'spell_dummysystem_melee_forbidden_dance'),
-- Meditate with the Forbidden Technique enchant: Forbidden Chants stacks
(965426, 'spell_dummysystem_melee_meditate'),
(965426, 'spell_dummysystem_melee_meditate_chants'),
-- Power Loop: finishers -> Maelstrom Weapon; Maelstrom Weapon consumed by a damaging spell -> combo points
(986075, 'spell_dummysystem_melee_power_loop'),
(53817, 'spell_dummysystem_melee_power_loop_maelstrom');

DELETE FROM `spell_proc` WHERE `SpellId` IN (997127, 954092, 273795, 271985, 1569658, 986233, 986075);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Bloodsail Captain: casting Mocking Blow (warrior family flag 0x08000000)
(997127, 0, 4, 0x08000000, 0x0, 0x0, 0x10, 0x7, 0x1, 0x0, 0x0, 0x0, 0, 100, 0, 0),
-- Demolish: the carrier takes a melee critical hit (auto attack or melee ability); effect 0 (the damage taken) is not
-- a proc effect
(954092, 0, 0, 0x0, 0x0, 0x0, 0x28, 0x1, 0x2, 0x2, 0x0, 0x1, 0, 100, 0, 0),
(273795, 0, 0, 0x0, 0x0, 0x0, 0x28, 0x1, 0x2, 0x2, 0x0, 0x1, 0, 100, 0, 0),
-- Forbidden Dance: Ambush (rogue family flag 0x200) hits
(271985, 0, 8, 0x00000200, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0x0, 0, 100, 0, 0),
(1569658, 0, 8, 0x00000200, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0x0, 0, 100, 0, 0),
(986233, 0, 8, 0x00000200, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0x0, 0, 100, 0, 0),
-- Power Loop: a finishing move is cast (the combo points are still there at the cast phase)
(986075, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0x0, 0, 100, 0, 0);
