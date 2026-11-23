-- Dummy-effect systems, area "Time" (src/server/coa/AscensionDummySystemTime.cpp): Steward of Eternity time spells,
-- Legacy of the Arcanist, Spreading Roots, Aegis Overdrive, Manawell, Frozen Chaos.

-- Legacy of the Arcanist talent 271284 stored only Fire through the generic enchant proc: the script stores every element
DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 271284;
DELETE FROM `spell_script_names` WHERE `spell_id` = 271284 AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';

DELETE FROM `spell_script_names` WHERE `ScriptName` IN (
    'spell_dummysystem_time_distortion', 'spell_dummysystem_time_eternity_heal', 'spell_dummysystem_time_eternity_mana',
    'spell_dummysystem_time_synchronize_stall', 'spell_dummysystem_time_synchronize_heal', 'spell_dummysystem_time_bind',
    'spell_dummysystem_time_arcanist_meteors', 'spell_dummysystem_time_arcanist_resonance',
    'spell_dummysystem_time_arcanist_store', 'spell_dummysystem_time_arcanist_unleash',
    'spell_dummysystem_time_mass_entanglement_spread', 'spell_dummysystem_time_spreading_roots',
    'spell_dummysystem_time_aegis_overdrive', 'spell_dummysystem_time_aegis_mana_shield',
    'spell_dummysystem_time_aegis_avoidance', 'spell_dummysystem_time_manawell', 'spell_dummysystem_time_frozen_chaos',
    'spell_dummysystem_time_frozen_chaos_crit', 'spell_dummysystem_time_frozen_chaos_conflagrate',
    'spell_dummysystem_time_frozen_embers');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Align / Time-bind / Synchronize (talent, enchant 986162 and ability sets)
(276343, 'spell_dummysystem_time_distortion'),
(276344, 'spell_dummysystem_time_distortion'),
(276345, 'spell_dummysystem_time_distortion'),
(986163, 'spell_dummysystem_time_distortion'),
(986164, 'spell_dummysystem_time_distortion'),
(986165, 'spell_dummysystem_time_distortion'),
(1576837, 'spell_dummysystem_time_distortion'),
(1576859, 'spell_dummysystem_time_distortion'),
(1576880, 'spell_dummysystem_time_distortion'),
(276354, 'spell_dummysystem_time_eternity_heal'),
(986173, 'spell_dummysystem_time_eternity_heal'),
(1576913, 'spell_dummysystem_time_eternity_heal'),
(276352, 'spell_dummysystem_time_eternity_mana'),
(986170, 'spell_dummysystem_time_eternity_mana'),
(1576912, 'spell_dummysystem_time_eternity_mana'),
(276345, 'spell_dummysystem_time_synchronize_stall'),
(986165, 'spell_dummysystem_time_synchronize_stall'),
(1576880, 'spell_dummysystem_time_synchronize_stall'),
(276350, 'spell_dummysystem_time_synchronize_heal'),
(986168, 'spell_dummysystem_time_synchronize_heal'),
(1576881, 'spell_dummysystem_time_synchronize_heal'),
(276344, 'spell_dummysystem_time_bind'),
(986164, 'spell_dummysystem_time_bind'),
(1576859, 'spell_dummysystem_time_bind'),
-- Legacy of the Arcanist: enchant 984117 meteors / Potential / motes, Resonance end, talent 271284 store + Meteor unleash
(984117, 'spell_dummysystem_time_arcanist_meteors'),
(984406, 'spell_dummysystem_time_arcanist_resonance'),
(984407, 'spell_dummysystem_time_arcanist_resonance'),
(984408, 'spell_dummysystem_time_arcanist_resonance'),
(984409, 'spell_dummysystem_time_arcanist_resonance'),
(271284, 'spell_dummysystem_time_arcanist_store'),
(760040, 'spell_dummysystem_time_arcanist_unleash'),
(760156, 'spell_dummysystem_time_arcanist_unleash'),
(760157, 'spell_dummysystem_time_arcanist_unleash'),
(760158, 'spell_dummysystem_time_arcanist_unleash'),
(760159, 'spell_dummysystem_time_arcanist_unleash'),
(760160, 'spell_dummysystem_time_arcanist_unleash'),
(760161, 'spell_dummysystem_time_arcanist_unleash'),
-- Spreading Roots (talent 283456 / enchant 954646)
(954507, 'spell_dummysystem_time_mass_entanglement_spread'),
(954643, 'spell_dummysystem_time_spreading_roots'),
(954644, 'spell_dummysystem_time_spreading_roots'),
(283457, 'spell_dummysystem_time_spreading_roots'),
(283458, 'spell_dummysystem_time_spreading_roots'),
-- Aegis Overdrive 299160: the talent, every Mana Shield rank and twin, the avoidance trigger
(299160, 'spell_dummysystem_time_aegis_overdrive'),
(1463, 'spell_dummysystem_time_aegis_mana_shield'),
(8494, 'spell_dummysystem_time_aegis_mana_shield'),
(8495, 'spell_dummysystem_time_aegis_mana_shield'),
(10191, 'spell_dummysystem_time_aegis_mana_shield'),
(10192, 'spell_dummysystem_time_aegis_mana_shield'),
(10193, 'spell_dummysystem_time_aegis_mana_shield'),
(27131, 'spell_dummysystem_time_aegis_mana_shield'),
(43019, 'spell_dummysystem_time_aegis_mana_shield'),
(43020, 'spell_dummysystem_time_aegis_mana_shield'),
(601463, 'spell_dummysystem_time_aegis_mana_shield'),
(1101463, 'spell_dummysystem_time_aegis_mana_shield'),
(1108494, 'spell_dummysystem_time_aegis_mana_shield'),
(1108495, 'spell_dummysystem_time_aegis_mana_shield'),
(1110191, 'spell_dummysystem_time_aegis_mana_shield'),
(1110192, 'spell_dummysystem_time_aegis_mana_shield'),
(1110193, 'spell_dummysystem_time_aegis_mana_shield'),
(1127131, 'spell_dummysystem_time_aegis_mana_shield'),
(1143019, 'spell_dummysystem_time_aegis_mana_shield'),
(1143020, 'spell_dummysystem_time_aegis_mana_shield'),
(1410693, 'spell_dummysystem_time_aegis_mana_shield'),
(299162, 'spell_dummysystem_time_aegis_avoidance'),
-- Manawell 954655: Lightwell Renew (every rank the Lightwell casts, and the twins)
(7001, 'spell_dummysystem_time_manawell'),
(27873, 'spell_dummysystem_time_manawell'),
(27874, 'spell_dummysystem_time_manawell'),
(28276, 'spell_dummysystem_time_manawell'),
(48084, 'spell_dummysystem_time_manawell'),
(48085, 'spell_dummysystem_time_manawell'),
(1107001, 'spell_dummysystem_time_manawell'),
(1127873, 'spell_dummysystem_time_manawell'),
(1127874, 'spell_dummysystem_time_manawell'),
(1128276, 'spell_dummysystem_time_manawell'),
(1148084, 'spell_dummysystem_time_manawell'),
(1148085, 'spell_dummysystem_time_manawell'),
-- Frozen Chaos 980673: helpers, Chaos Bolt (every rank) for Frozen Embers
(980673, 'spell_dummysystem_time_frozen_chaos'),
(980674, 'spell_dummysystem_time_frozen_chaos_crit'),
(980677, 'spell_dummysystem_time_frozen_chaos_conflagrate'),
(50796, 'spell_dummysystem_time_frozen_embers'),
(50865, 'spell_dummysystem_time_frozen_embers'),
(50866, 'spell_dummysystem_time_frozen_embers'),
(59170, 'spell_dummysystem_time_frozen_embers'),
(59171, 'spell_dummysystem_time_frozen_embers'),
(59172, 'spell_dummysystem_time_frozen_embers');

DELETE FROM `spell_proc` WHERE `SpellId` IN (276344, 986164, 1576859, 984117, 271284, 299160, 299162, 980674, 980675,
    980677);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Time-bind bonds: every damage the bonded ally takes (triggered damage included)
(276344, 0, 0, 0, 0, 0, 0x100000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(986164, 0, 0, 0, 0, 0, 0x100000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(1576859, 0, 0, 0, 0, 0, 0x100000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Legacy of the Arcanist (enchant and talent): direct Fire / Nature / Frost / Arcane spell damage
(984117, 0x5C, 0, 0, 0, 0, 0x11000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(271284, 0x5C, 0, 0, 0, 0, 0x11000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Aegis Overdrive: Mana Shield applied; the avoidance trigger on a dodge, parry or block (20%, once per 5 sec)
(299160, 0, 3, 0x8000, 0, 0, 0x4400, 0x4, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(299162, 0, 0, 0, 0, 0, 0x28, 0x7, 0x2, 0x70, 0x0, 0, 0, 20, 5000, 0),
-- Frozen Chaos: Frost criticals (spell list in the script); a Chaos Bolt hit spends a charge (no
-- PROC_ATTR_REQ_SPELLMOD: the aura's modifiers use Ascension SpellModOps 36 / 38, which the core does not load as spell
-- mods, so Chaos Bolt never "uses" one); Conflagrate grants Splintered Chaos
(980674, 0, 0, 0, 0, 0, 0x10000, 0x1, 0x2, 0x2, 0x0, 0, 0, 100, 0, 0),
(980675, 0, 5, 0, 0x20000, 0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(980677, 0, 5, 0, 0x800000, 0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);
