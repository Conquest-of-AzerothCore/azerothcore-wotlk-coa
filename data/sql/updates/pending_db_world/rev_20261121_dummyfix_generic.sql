-- Class-neutral spells and Mystic Enchants whose behaviour lived in an unhandled dummy effect
-- (tools/dummy_census/fix-batches/generic-*.md); scripts in src/server/coa/AscensionDummyFixGeneric.cpp.
DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_generic_%';

-- ===== generic-01 =====
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Arcane / Fiery / Frosty / Shadow Charge enchants, Arcane Charge talent, Scattered Burst: cast on Charge / Scatter Shot
(92252, 'spell_dummyfix_generic_cast_on_use'),
(92247, 'spell_dummyfix_generic_cast_on_use'),
(92249, 'spell_dummyfix_generic_cast_on_use'),
(92250, 'spell_dummyfix_generic_cast_on_use'),
(282881, 'spell_dummyfix_generic_cast_on_use'),
(283449, 'spell_dummyfix_generic_cast_on_use'),
(954641, 'spell_dummyfix_generic_cast_on_use'),
-- Macro-Gravity (6 stacks: stun)
(280271, 'spell_dummyfix_generic_stack_threshold'),
-- Overloaded Froststorm / Astral Tempest: Overloaded stacks, at 10 the storm on the struck target
(81122, 'spell_dummyfix_generic_overloaded'),
(81479, 'spell_dummyfix_generic_overloaded'),
-- Sniper: standing still
(81166, 'spell_dummyfix_generic_standing_still'),
(281475, 'spell_dummyfix_generic_standing_still'),
(280215, 'spell_dummyfix_generic_shoulder_the_burden'),
(280380, 'spell_dummyfix_generic_xorothian_sigil'),
(299031, 'spell_dummyfix_generic_arcane_breach'),
(280100, 'spell_dummyfix_generic_bonds_of_justice'),
(282353, 'spell_dummyfix_generic_lunar_spirits'),
(84535, 'spell_dummyfix_generic_lunar_spirits'),
(282354, 'spell_dummyfix_generic_lunar_spirits_spread'),
(84536, 'spell_dummyfix_generic_lunar_spirits_spread');

DELETE FROM `spell_proc` WHERE `SpellId` IN (92252, 92247, 92249, 92250, 282881, 283449, 954641, 299031, 282353, 84535, 81122, 81479);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- elemental Charge enchants / Arcane Charge talent: Charge (or Feral Charge) landing; the script checks the spell
(92252, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(92247, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(92249, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(92250, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(282881, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Scattered Burst: Scatter Shot landing
(283449, 0, 9, 0x40000, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(954641, 0, 9, 0x40000, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Arcane Breach (on the marked enemy): the marker's Charge / Intercept landing on it, consumed (1 charge)
(299031, 0, 4, 0x40000001, 0x0, 0x0, 0x22220, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 1),
-- Lunar Spirits: Arcane Missile damage (a triggered spell); the script checks the caster's Moonfire on the target
(282353, 0, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
(84535, 0, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 0, 0),
-- Overloaded Froststorm / Astral Tempest: a stack of Overloaded (81123) from direct Nature or Frost (Froststorm) /
-- Nature or Arcane (Astral Tempest) spell damage
(81122, 24, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(81479, 72, 0, 0x0, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- Sunwell: the 30 sec form carries the periodic fear / sleep / charm dispel (280646 -> 280647)
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 280645 AND `spell_effect` = 280646;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(280645, 280646, 2, 'Sunwell: periodic fear/sleep/charm dispel while the form lasts');

-- ===== generic-02 / generic-03 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((81128, 'spell_dummyfix_generic_standing_still'), (283273, 'spell_dummyfix_generic_impeccable_timing_periodic'), (944401, 'spell_dummyfix_generic_impeccable_timing_periodic'), (283275, 'spell_dummyfix_generic_impeccable_timing'), (273021, 'spell_dummyfix_generic_blessing_of_the_divines'), (965477, 'spell_dummyfix_generic_blessing_of_the_divines'), (273020, 'spell_dummyfix_generic_blessing_of_the_divines_proc'), (965476, 'spell_dummyfix_generic_blessing_of_the_divines_proc'), (283210, 'spell_dummyfix_generic_genesis_barkskin'), (965936, 'spell_dummyfix_generic_genesis_barkskin'), (283209, 'spell_dummyfix_generic_bear_form_proc'), (911165, 'spell_dummyfix_generic_bear_form_proc'), (81096, 'spell_dummyfix_generic_raising_hell'), (281336, 'spell_dummyfix_generic_raising_hell'), (283039, 'spell_dummyfix_generic_shadow_core'), (410604, 'spell_dummyfix_generic_shadow_core'), (283417, 'spell_dummyfix_generic_void_teleportation'), (954626, 'spell_dummyfix_generic_void_teleportation'), (283484, 'spell_dummyfix_generic_deadly_leap'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Ready, Set, Go!: standing still in combat
(81128, 'spell_dummyfix_generic_standing_still'),
-- Impeccable Timing: every 10 sec (Biding Time), the next listed spell grants Missile Barrage
(283273, 'spell_dummyfix_generic_impeccable_timing_periodic'),
(944401, 'spell_dummyfix_generic_impeccable_timing_periodic'),
(283275, 'spell_dummyfix_generic_impeccable_timing'),
-- Blessing of the Divines: a random blessing of the pool; the parents proc on costed direct Holy / Nature heals
(273021, 'spell_dummyfix_generic_blessing_of_the_divines'),
(965477, 'spell_dummyfix_generic_blessing_of_the_divines'),
(273020, 'spell_dummyfix_generic_blessing_of_the_divines_proc'),
(965476, 'spell_dummyfix_generic_blessing_of_the_divines_proc'),
-- Genesis Barkskin: +1 sec Barkskin; One with the Forest procs on melee crits in Bear / Dire Bear Form
(283210, 'spell_dummyfix_generic_genesis_barkskin'),
(965936, 'spell_dummyfix_generic_genesis_barkskin'),
(283209, 'spell_dummyfix_generic_bear_form_proc'),
(911165, 'spell_dummyfix_generic_bear_form_proc'),
-- Raising Hell: the demon casts the same Hellfire
(81096, 'spell_dummyfix_generic_raising_hell'),
(281336, 'spell_dummyfix_generic_raising_hell'),
-- Shadow Core: Mind Blast grants Molten Core charges
(283039, 'spell_dummyfix_generic_shadow_core'),
(410604, 'spell_dummyfix_generic_shadow_core'),
-- Void Teleportation: Void Shift swaps positions
(283417, 'spell_dummyfix_generic_void_teleportation'),
(954626, 'spell_dummyfix_generic_void_teleportation'),
-- Deadly Leap dummy: a killing Heroic Leap resets its cooldown
(283484, 'spell_dummyfix_generic_deadly_leap');

DELETE FROM `spell_proc` WHERE `SpellId` IN (283275, 273020, 965476, 283209, 911165, 81096, 281336, 283038, 410602, 283417, 954626, 911162);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Impeccable Timing: the next listed spell cast (script), used up
(283275, 0, 0, 0x0, 0x0, 0x0, 0x15400, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 1),
-- Blessing of the Divines: direct Holy / Nature heals (the script checks the cost); talent 10%, once a second
(273020, 10, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 10, 1000, 0),
(965476, 10, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x0, 0x0, 0, 0, 35, 0, 0),
-- One with the Forest: melee critical strikes (the script checks Bear / Dire Bear Form), once a second
(283209, 0, 0, 0x0, 0x0, 0x0, 0x14, 0x1, 0x2, 0x2, 0x0, 0, 0, 100, 1000, 0),
(911165, 0, 0, 0x0, 0x0, 0x0, 0x14, 0x1, 0x2, 0x2, 0x0, 0, 0, 100, 1000, 0),
-- Raising Hell: casting Hellfire (cast or hit phase of the self-cast channel)
(81096, 0, 5, 0x40, 0x0, 0x0, 0x15400, 0x7, 0x3, 0x0, 0x0, 0, 0, 100, 0, 0),
(281336, 0, 5, 0x40, 0x0, 0x0, 0x15400, 0x7, 0x3, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Shadow Core: casting Mind Blast
(283038, 0, 6, 0x2000, 0x0, 0x0, 0x11000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(410602, 0, 6, 0x2000, 0x0, 0x0, 0x11000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Void Teleportation: Void Shift landing
(283417, 0, 6, 0x0, 0x0, 0x1000000, 0x15400, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(954626, 0, 6, 0x0, 0x0, 0x1000000, 0x15400, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Scorched Ground enchant 911162: Living Bomb's explosion (triggered) leaves 411160, once every 8 sec (its ICD marker
-- 411162 is not needed)
(911162, 0, 3, 0x0, 0x10000, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 8000, 0);

-- Scorched Ground WCR enchant 1583854: "can only occur once every 8 seconds" (its ICD marker 1583856 is not needed)
UPDATE `coa_mystic_enchant_proc` SET `cooldown_ms` = 8000 WHERE `enchant_spell` = 1583854 AND `effect` = 0;

-- ===== generic-04 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((299938, 'spell_dummyfix_generic_elemental_reload'), (283405, 'spell_dummyfix_generic_finale'), (954436, 'spell_dummyfix_generic_finale'), (299944, 'spell_dummyfix_generic_buff_while'), (283200, 'spell_dummyfix_generic_scorched_ground'), (299180, 'spell_dummyfix_generic_tempered_by_chaos'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(299938, 'spell_dummyfix_generic_elemental_reload'),
(283405, 'spell_dummyfix_generic_finale'),
(954436, 'spell_dummyfix_generic_finale'),
(299944, 'spell_dummyfix_generic_buff_while'),
(283200, 'spell_dummyfix_generic_scorched_ground'),
(299180, 'spell_dummyfix_generic_tempered_by_chaos');

DELETE FROM `spell_proc` WHERE `SpellId` IN (299938, 283405, 954436, 299190, 283200, 299180);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Elemental Reload: Elemental Blast dealing damage
(299938, 0, 11, 0x0, 0x0, 0x20000000, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Enraging / Titanic Finale: casting a finishing move (combo points still counted), once every 20 sec
(283405, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 20000, 0),
(954436, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 20000, 0),
-- Molded by Darkness: Haunt dealing damage
(299190, 0, 5, 0x0, 0x40000, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Scorched Ground: Living Bomb's explosion (triggered) dealing damage, once every 8 sec
(283200, 0, 3, 0x0, 0x10000, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x2, 0, 0, 100, 8000, 0),
-- Tempered by Chaos: casting Incinerate or Chaos Bolt (the script checks Molten Core)
(299180, 0, 5, 0x0, 0x20040, 0x0, 0x10000, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ===== generic-05 .. generic-08 =====
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((299988, 'spell_dummyfix_generic_buff_while'), (276308, 'spell_dummyfix_generic_violent_combo'), (954322, 'spell_dummyfix_generic_learn_with'), (965505, 'spell_dummyfix_generic_target_icd'), (84506, 'spell_dummyfix_generic_target_icd'), (1180331, 'spell_dummyfix_generic_savage_roar_duration'), (965899, 'spell_dummyfix_generic_stack_threshold'), (832714, 'spell_dummyfix_generic_assuaging_shadows'), (965334, 'spell_dummyfix_generic_assuaging_shadows_proc'), (283585, 'spell_dummyfix_generic_bane_of_the_wicked'), (280330, 'spell_dummyfix_generic_cauterize'), (280110, 'spell_dummyfix_generic_stormcloak'), (280120, 'spell_dummyfix_generic_timeguard'), (280630, 'spell_dummyfix_generic_celestial_form'), (281120, 'spell_dummyfix_generic_dimensional_divergence'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Vengeful Plague: 299989 while Seal of Vengeance is on
(299988, 'spell_dummyfix_generic_buff_while'),
(276308, 'spell_dummyfix_generic_violent_combo'),
-- Blazing Barrier: knowing Combustion teaches Blazing Barrier
(954322, 'spell_dummyfix_generic_learn_with'),
-- Harbinger of Flame / Unbounded Deathbringer: no proc on a target still carrying the owner's ICD marker
(965505, 'spell_dummyfix_generic_target_icd'),
(84506, 'spell_dummyfix_generic_target_icd'),
(1180331, 'spell_dummyfix_generic_savage_roar_duration'),
-- Soul Fragment: 9 fragments -> Shadow Visions
(965899, 'spell_dummyfix_generic_stack_threshold'),
-- Assuaging Shadows: Backstab -> Shadow Dance cooldown -1 sec
(832714, 'spell_dummyfix_generic_assuaging_shadows'),
(965334, 'spell_dummyfix_generic_assuaging_shadows_proc'),
(283585, 'spell_dummyfix_generic_bane_of_the_wicked'),
(280330, 'spell_dummyfix_generic_cauterize'),
(280110, 'spell_dummyfix_generic_stormcloak'),
(280120, 'spell_dummyfix_generic_timeguard'),
(280630, 'spell_dummyfix_generic_celestial_form'),
(281120, 'spell_dummyfix_generic_dimensional_divergence');

DELETE FROM `spell_proc` WHERE `SpellId` IN (276308, 280630, 84810);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Violent Combo: a finishing move landing (the script checks it is one), h% = 20
(276308, 0, 0, 0x0, 0x0, 0x0, 0x11110, 0x7, 0x2, 0x0, 0x0, 0, 0, 20, 0, 0),
-- Celestial Form: a direct healing critical strike
(280630, 0, 0, 0x0, 0x0, 0x0, 0x4000, 0x2, 0x2, 0x2, 0x0, 0, 0, 100, 0, 0),
-- Abiding Fel Energy: direct damaging abilities and spells (not auto attacks), once a second
(84810, 0, 0, 0x0, 0x0, 0x0, 0x10110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 1000, 0);

-- Shadow Marks of Assuaging Shadows: the marker's Ambush (/ Ravage) on the marked enemy
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((832713, 'spell_dummyfix_generic_shadow_mark'), (1571107, 'spell_dummyfix_generic_shadow_mark'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(832713, 'spell_dummyfix_generic_shadow_mark'),
(1571107, 'spell_dummyfix_generic_shadow_mark');
DELETE FROM `spell_proc` WHERE `SpellId` IN (832713, 1571107);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(832713, 0, 0, 0x0, 0x0, 0x0, 0x20, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 5),
(1571107, 0, 0, 0x0, 0x0, 0x0, 0x20, 0x7, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);
