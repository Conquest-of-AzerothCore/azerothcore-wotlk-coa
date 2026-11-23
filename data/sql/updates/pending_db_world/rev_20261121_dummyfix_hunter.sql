-- Hunter-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/hunter-*.md);
-- scripts in src/server/coa/AscensionDummyFixHunter.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_hunter_%';
DELETE FROM `spell_script_names` WHERE `spell_id` IN (983035) AND `ScriptName` = 'spell_ascension_mystic_enchant_proc';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Beast Shot CDR Randomizer: one of Kill Command / Frenzy Shot / Bestial Wrath's cooldown cut, at random
(285070, 'spell_dummyfix_hunter_beast_shot_randomizer'),
(983041, 'spell_dummyfix_hunter_beast_shot_randomizer'),
-- Bloodmage's Beast Shot: generic Mystic Enchant proc rule below (crit on a Beast Shot target, once per second)
(983035, 'spell_ascension_mystic_enchant_proc'),
-- Companions: tamed pets' auto attacks deal the periodic dummy's school
(81418, 'spell_dummyfix_hunter_companion'),
(81419, 'spell_dummyfix_hunter_companion'),
(81420, 'spell_dummyfix_hunter_companion'),
(81421, 'spell_dummyfix_hunter_companion'),
(81422, 'spell_dummyfix_hunter_companion'),
(281958, 'spell_dummyfix_hunter_companion'),
(281963, 'spell_dummyfix_hunter_companion'),
(281968, 'spell_dummyfix_hunter_companion'),
(281973, 'spell_dummyfix_hunter_companion'),
(281978, 'spell_dummyfix_hunter_companion'),
-- Molten Ammo: Aimed Shot, Steady Shot and Multi-Shot add 50% as Fire damage (277820)
(277819, 'spell_dummyfix_hunter_molten_ammo'),
-- Tundra Tracker: shots stack 277488 (Steady Shot 3) without refreshing it; 9 stacks -> Fingers of Frost if known
(277493, 'spell_dummyfix_hunter_tundra_tracker'),
-- Seething Flames: ticks cast 84758 (target and nearby enemies), not the stock Explosive Shot trigger
(84516, 'spell_dummyfix_hunter_seething_flames');

DELETE FROM `spell_proc` WHERE `SpellId` IN (983035, 277819, 277493);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Bloodmage's Beast Shot (no DBC proc flags): critical direct damage from Hunter abilities (melee, ranged or magic
-- class; no auto shot, no periodic); only effect 1 (the randomizer trigger) procs
(983035, 0, 9, 0x0, 0x0, 0x0, 0x10110, 0x1, 0x2, 0x2, 0x0, 0x5, 0, 100, 0, 0),
-- Molten Ammo: damage from Aimed Shot (0x20000), Multi-Shot (0x1000), Steady Shot (flag 1 0x1)
(277819, 0, 9, 0x21000, 0x1, 0x0, 0x100, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Tundra Tracker: casting a Hunter shot (the script keeps ranged-class Hunter spells)
(277493, 0, 9, 0x0, 0x0, 0x0, 0x100, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` IN (983035);
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(983035, 1, 0, 'critical_damage', 0, '', 100, 1000, '', '983037', '', '', '', 0, 0, 'Bloodmage''s Beast Shot (enchant 983035): a Hunter direct damage crit on your Beast Shot target cuts one random cooldown (983041), at most once per second');

-- ---- chunk 02 (fix-batches/hunter-02.md)
DELETE FROM `spell_script_names` WHERE `spell_id` IN (118475) AND `ScriptName` = 'spell_hun_glyph_of_arcane_shot';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Waxing Moon: at 5 stacks Moonfire triggers the explosion 983848
(983846, 'spell_dummyfix_hunter_waxing_moon'),
-- Fel Energy: stacks once per second from direct damage / heals; the cap consumes them for the grant
(84806, 'spell_dummyfix_hunter_fel_energy'),
(84805, 'spell_dummyfix_hunter_fel_energy'),
-- Focused Burst: each missile 10% weaker than the hit before
(284083, 'spell_dummyfix_hunter_focused_burst'),
(978761, 'spell_dummyfix_hunter_focused_burst'),
-- Lone Wolf: damage buff while no pet is active
(52783, 'spell_dummyfix_hunter_lone_wolf'),
(52785, 'spell_dummyfix_hunter_lone_wolf'),
-- Forbidden Powers: Forbidden Technique's Shadow Dance ending grants Shadow Powers
(271999, 'spell_dummyfix_hunter_forbidden_technique_dance'),
-- Glyph of Arcane Shot (Ascension copy of 56841): the stock mana refund on a stung target
(118475, 'spell_hun_glyph_of_arcane_shot');

DELETE FROM `spell_proc` WHERE `SpellId` IN (983846, 84806, 84805, 276669, 118475);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Waxing Moon: Moonfire's direct hit (druid family flag 0x2); the script requires the full 5 stacks
(983846, 0, 7, 0x2, 0x0, 0x0, 0x10000, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Fel Strike / Abiding Fel Energy (no DBC proc flags): direct damage or heal from any ability; only the stack effect
-- procs (Fel Strike e1, Abiding Fel Energy e0)
(84806, 0, 0, 0x0, 0x0, 0x0, 0x15510, 0x3, 0x2, 0x0, 0x0, 0x5, 0, 100, 0, 0),
(84805, 0, 0, 0x0, 0x0, 0x0, 0x15510, 0x3, 0x2, 0x0, 0x0, 0x2, 0, 100, 0, 0),
-- Defias Gunslinger: Sinister Strike (rogue family flag 0x2) hitting
(276669, 0, 8, 0x2, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Glyph of Arcane Shot: Arcane Shot (0x800) hitting, as stock 56841
(118475, 0, 9, 0x800, 0x0, 0x0, 0x100, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `spell_linked_spell` WHERE `spell_trigger` IN (34482, 34483, 34484) AND `spell_effect` IN (834482, 834483, 834484);
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(34482, 834482, 2, 'Careful Aim rank 1: RAP from Intellect and hit chance (dummyfix hunter)'),
(34483, 834483, 2, 'Careful Aim rank 2: RAP from Intellect and hit chance (dummyfix hunter)'),
(34484, 834484, 2, 'Careful Aim rank 3: RAP from Intellect and hit chance (dummyfix hunter)');

-- ---- chunk 03 (fix-batches/hunter-03.md)
DELETE FROM `spell_script_names` WHERE `spell_id` IN (934497) AND `ScriptName` = 'spell_hun_thrill_of_the_hunt';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- (Glyphs of Aspect of the Viper 118495 / Freezing Trap 118482 need nothing: the stock code finds them as namesakes
-- of 56851 / 56845 through GetSpellAndRelatives)
-- Talonshrike: 277791 while a single two-hander is wielded
(277790, 'spell_dummyfix_hunter_talonshrike'),
-- Nesingwary's Big Game Shot: Aimed Shot on the hunter's own Hunter's Mark target
(982375, 'spell_dummyfix_hunter_big_game_shot'),
-- Thrill of the Hunt copy 934497: the stock 40% mana refund on a shot crit
(934497, 'spell_hun_thrill_of_the_hunt');

DELETE FROM `spell_proc` WHERE `SpellId` IN (276668, 997054, 277791, 982375, 934497);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Swashbuckling Duelist: Sinister Strike (rogue family flag 0x2) hitting grants 997054
(276668, 0, 8, 0x2, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- 997054: the next Mongoose Bite (flag 2 0x2000000) hitting triggers Pirate's Flurry (997430), one charge
(997054, 0, 9, 0x0, 0x0, 0x2000000, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 1),
-- Talonshrike buff: Raptor Strike (flag 2 0x10000) cuts Fury of the Eagle's cooldown (effect 1 only)
(277791, 0, 9, 0x0, 0x0, 0x10000, 0x10, 0x1, 0x2, 0x0, 0x0, 0x1, 0, 100, 0, 0),
-- Nesingwary's Big Game Shot: Aimed Shot (0x20000) hitting; only effect 1 (Hunting) procs
(982375, 0, 9, 0x20000, 0x0, 0x0, 0x100, 0x1, 0x2, 0x0, 0x0, 0x1, 0, 100, 0, 0),
-- Thrill of the Hunt copy: a Hunter shot critting, 15% (tooltip)
(934497, 0, 9, 0x0, 0x0, 0x0, 0x100, 0x1, 0x2, 0x2, 0x0, 0, 0, 15, 0, 0);

-- ---- chunk 04 (fix-batches/hunter-04.md)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((272353, 'spell_dummyfix_hunter_deadly_bite'), (1133045, 'spell_dummyfix_hunter_binding_shot'), (953228, 'spell_dummyfix_hunter_rapid_recuperation'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Deadly Bite: the bleed accumulates s1% of each triggering hit
(272353, 'spell_dummyfix_hunter_deadly_bite'),
-- Binding Shot: moving more than 5 yd from the arrow stuns (1133047)
(1133045, 'spell_dummyfix_hunter_binding_shot'),
-- Rapid Recuperation copy: Rapid Fire / Rapid Killing mana (Spot Weakness 1589722 and Bullseye! are UnitScript hooks)
(953228, 'spell_dummyfix_hunter_rapid_recuperation');

DELETE FROM `spell_proc` WHERE `SpellId` IN (272353, 953228);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Deadly Bite: damage from Savage Blade (0x80000), Counterattack (flag 1 0x80000), Mongoose Bite (flag 2 0x2000000);
-- effect 1 (aura 286) does not proc
(272353, 0, 9, 0x80000, 0x80000, 0x2000000, 0x110, 0x1, 0x2, 0x0, 0x0, 0x2, 0, 100, 0, 0),
-- Rapid Recuperation copy: as stock -53228 (Rapid Fire 0x20, Rapid Killing flag 1 0x1000000), DBC proc flags
(953228, 0, 9, 0x20, 0x1000000, 0x0, 0x0, 0x4, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0);

-- ---- chunk 05 (fix-batches/hunter-05.md)
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN ((283549, 'spell_dummyfix_hunter_deadly_aim'), (965898, 'spell_dummyfix_hunter_deadly_aim'), (1584974, 'spell_dummyfix_hunter_deadly_aim'), (956445, 'spell_dummyfix_hunter_paratrooper'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Deadly Aim: the buff resets Aimed Shot (and Multi-Shot for 1584974)
(283549, 'spell_dummyfix_hunter_deadly_aim'),
(965898, 'spell_dummyfix_hunter_deadly_aim'),
(1584974, 'spell_dummyfix_hunter_deadly_aim'),
-- Paratrooper: Hunter shots on monsters cut Disengage / Paratrooper by 10.5 s, once per second
(956445, 'spell_dummyfix_hunter_paratrooper');

DELETE FROM `spell_proc` WHERE `SpellId` IN (956445);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Paratrooper: a Hunter shot (ranged class) hitting; effect 0 (a 0-value modifier) does not proc
(956445, 0, 9, 0x0, 0x0, 0x0, 0x100, 0x1, 0x2, 0x0, 0x0, 0x1, 0, 100, 0, 0);
