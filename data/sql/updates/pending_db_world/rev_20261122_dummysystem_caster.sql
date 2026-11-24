-- Caster systems the dummy fixes were missing (tools/dummy_census/SYSTEMS-BRIEF.md, task C); scripts in
-- src/server/coa/AscensionDummySystemCaster.cpp. Apostle of Eredath's casts, the Burning Determination capstone and
-- Blazing Determination's cast shield are AllSpellScript hooks there (no binding).

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummysystem_caster_%';
-- Death Pact ranks 2-3 and the Reborn copy lacked the stock script: without its target filter the instakill effect
-- took every friendly unit within 100 yd instead of the caster's undead minion
DELETE FROM `spell_script_names` WHERE `spell_id` IN (48843, 48844, 1148743) AND `ScriptName` = 'spell_dk_death_pact';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Soul Swap: copy the caster's damage-over-time effects; Exhale puts the copies on another target
(954614, 'spell_dummysystem_caster_soul_swap'),
(2304614, 'spell_dummysystem_caster_soul_swap'),
(954615, 'spell_dummysystem_caster_soul_swap_held'),
(2304615, 'spell_dummysystem_caster_soul_swap_held'),
(954853, 'spell_dummysystem_caster_soul_swap_exhale'),
(2304853, 'spell_dummysystem_caster_soul_swap_exhale'),
-- Apostle of Eredath: teaches Beam of Hatred
(902185, 'spell_dummysystem_caster_apostle_of_eredath'),
-- Shadow Visions: Soul Fragments from Mind Flay, the buff and its empowerments, Psychic Surge's decay
(272524, 'spell_dummysystem_caster_shadow_visions_fragments'),
(272515, 'spell_dummysystem_caster_shadow_visions'),
(1570626, 'spell_dummysystem_caster_shadow_visions'),
(272520, 'spell_dummysystem_caster_psychic_surge'),
(1570630, 'spell_dummysystem_caster_psychic_surge'),
-- Unsealed (Improved Judgements capstone) and Elemental Conviction: spells that trigger the active seal
(825958, 'spell_dummysystem_caster_unsealed'),
(998850, 'spell_dummysystem_caster_elemental_conviction'),
-- Skeleton King: Death Pact keeps the minion; Bone Shield ends the maximum health bonus
(48743, 'spell_dummysystem_caster_skeleton_king_death_pact'),
(48843, 'spell_dummysystem_caster_skeleton_king_death_pact'),
(48844, 'spell_dummysystem_caster_skeleton_king_death_pact'),
(1148743, 'spell_dummysystem_caster_skeleton_king_death_pact'),
(49222, 'spell_dummysystem_caster_skeleton_king_bone_shield'),
(1149222, 'spell_dummysystem_caster_skeleton_king_bone_shield'),
(1249222, 'spell_dummysystem_caster_skeleton_king_bone_shield'),
(48843, 'spell_dk_death_pact'),
(48844, 'spell_dk_death_pact'),
(1148743, 'spell_dk_death_pact');

DELETE FROM `spell_proc` WHERE `SpellId` IN (272524, 272515, 1570626, 272520, 1570630, 825958, 998850);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Shadow Visions talent: each Mind Flay damage tick (58381 and ranks, triggered by the channel)
(272524, 0, 6, 0x00800000, 0x00000000, 0x00000000, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 100, 0, 0),
-- Shadow Visions buff: the first Mind Blast, Devouring Plague or Vampiric Touch to land
(272515, 0, 6, 0x02002000, 0x00000400, 0x00000000, 0x10000, 0x5, 0x2, 0x0, 0x0, 0, 100, 0, 0),
(1570626, 0, 6, 0x02002000, 0x00000400, 0x00000000, 0x10000, 0x5, 0x2, 0x0, 0x0, 0, 100, 0, 0),
-- Psychic Surge: each Mind Flay / Mind Sear damage event (both are triggered by their channels)
(272520, 0, 6, 0x00800000, 0x00080000, 0x00000000, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 100, 0, 0),
(1570630, 0, 6, 0x00800000, 0x00080000, 0x00000000, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 100, 0, 0),
-- Unsealed: damaging magic or ranged spells; the script keeps the non-instant Holy spells and ranged abilities
(825958, 0, 0, 0x00000000, 0x00000000, 0x00000000, 0x10100, 0x1, 0x2, 0x0, 0x0, 0, 100, 0, 0),
-- Elemental Conviction: Lightning Bolt, Chain Lightning, Lava Burst, Elemental Blast hits (not Lightning Overload)
(998850, 0, 11, 0x00000003, 0x00001000, 0x20000000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 100, 0, 0);
