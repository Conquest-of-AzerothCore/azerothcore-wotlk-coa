-- Rogue-family spells whose behaviour lived in an unhandled dummy effect (tools/dummy_census/fix-batches/rogue-*.md);
-- scripts in src/server/coa/AscensionDummyFixRogue.cpp.

DELETE FROM `spell_script_names` WHERE `ScriptName` LIKE 'spell_dummyfix_rogue_%';
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_rog_rupture' AND `spell_id` BETWEEN 904960 AND 907068;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_ascension_mystic_enchant_proc' AND `spell_id` = 283139;
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- finishing moves: chance per combo point to grant / cast the effect's spell
(285279, 'spell_dummyfix_rogue_finisher_proc'),  -- Adrenaline Junkie -> 285283 (Adrenaline Rush cooldown)
(1589466, 'spell_dummyfix_rogue_finisher_proc'), -- Adrenaline Junkie (WCR) -> 1589467
(283833, 'spell_dummyfix_rogue_finisher_proc'),  -- Deadly Combo -> 283835 (Sudden Death)
(977856, 'spell_dummyfix_rogue_finisher_proc'),  -- Deadly Combo (enchant) -> 977858
(285111, 'spell_dummyfix_rogue_finisher_proc'),  -- Swashbuckler: Bloodsail -> 285115
(983110, 'spell_dummyfix_rogue_finisher_proc'),  -- Swashbuckler: Bloodsail (enchant) -> 983111
(277924, 'spell_dummyfix_rogue_finisher_proc'),  -- Goremaw's Bite -> 277923
(285017, 'spell_dummyfix_rogue_finisher_proc'),  -- Ready for Mayhem -> 285019
(284148, 'spell_dummyfix_rogue_finisher_proc'),  -- Cobra Combo -> 979105 on the pet
(979106, 'spell_dummyfix_rogue_finisher_proc'),  -- Cobra Combo (enchant) -> 979105 on the pet
(275094, 'spell_dummyfix_rogue_finisher_proc'),  -- Double Team -> 275096
(285477, 'spell_dummyfix_rogue_finisher_proc'),  -- Blade Vortex -> 986043 (during Blade Flurry)
(986038, 'spell_dummyfix_rogue_finisher_proc'),  -- Blade Vortex (enchant) -> 986043 (during Blade Flurry)
-- "if you know X you also learn Y"
(979113, 'spell_dummyfix_rogue_learn_with'),     -- Poison Mastery -> Poison Bomb 979114
(979080, 'spell_dummyfix_rogue_learn_with'),     -- Shiv -> Deadly Follow-up 979081
(977810, 'spell_dummyfix_rogue_learn_with'),     -- Titan's Grip -> Titanic Strike 977813
-- Poison Bomb: Deadly Poison stacks from the throw and the fumes
(284169, 'spell_dummyfix_rogue_poison_bomb'),
(979114, 'spell_dummyfix_rogue_poison_bomb'),
(1586625, 'spell_dummyfix_rogue_poison_bomb'),
(284171, 'spell_dummyfix_rogue_poison_bomb'),
(979115, 'spell_dummyfix_rogue_poison_bomb'),
(1586626, 'spell_dummyfix_rogue_poison_bomb'),
-- Shadow Blades: builders +15% as Shadow and +1 combo point
(1180000, 'spell_dummyfix_rogue_shadow_blades'),
-- Instigator: Ghostly Strike / Riposte +50% above 75% target health
(14278, 'spell_dummyfix_rogue_instigator'),
(1114278, 'spell_dummyfix_rogue_instigator'),
(1214278, 'spell_dummyfix_rogue_instigator'),
(1398241, 'spell_dummyfix_rogue_instigator'),
(1464278, 'spell_dummyfix_rogue_instigator'),
(14251, 'spell_dummyfix_rogue_instigator'),
(1114251, 'spell_dummyfix_rogue_instigator'),
(1214251, 'spell_dummyfix_rogue_instigator'),
(1398240, 'spell_dummyfix_rogue_instigator'),
(1464251, 'spell_dummyfix_rogue_instigator'),
-- Consumed By Shadows: leaving Stealth enters Shadowform
(1784, 'spell_dummyfix_rogue_stealth'),
(1101784, 'spell_dummyfix_rogue_stealth'),
-- Bathe in Blood: a stack per bleed on the target
(275864, 'spell_dummyfix_rogue_bathe_in_blood'),
(983097, 'spell_dummyfix_rogue_bathe_in_blood'),
-- Freezing Blood: Cold Blood used up grants 284210
(14177, 'spell_dummyfix_rogue_cold_blood'),
(1114177, 'spell_dummyfix_rogue_cold_blood'),
(1214177, 'spell_dummyfix_rogue_cold_blood'),
-- Glyph of Preparation (classless 118438): Preparation resets Blade Flurry, Dismantle, Kick
(14185, 'spell_dummyfix_rogue_preparation'),
(1114185, 'spell_dummyfix_rogue_preparation'),
(1214185, 'spell_dummyfix_rogue_preparation'),
-- Massacre talent: the Killing Spree teleport applies 283135
(57840, 'spell_dummyfix_rogue_massacre'),
(1157840, 'spell_dummyfix_rogue_massacre'),
-- Dual Wield Specialization: +2% crit while an off-hand weapon is equipped
(913715, 'spell_dummyfix_rogue_dual_wield_specialization'),
-- Aether / Dawn / Flare / Storm / Void Spree: Killing Spree with their own blitz
(913465, 'spell_dummyfix_rogue_spree'),
(913462, 'spell_dummyfix_rogue_spree'),
(913450, 'spell_dummyfix_rogue_spree'),
(913456, 'spell_dummyfix_rogue_spree'),
(913459, 'spell_dummyfix_rogue_spree'),
-- Apprentice of Shadows: Master of Shadows only at 3 stacks, which are used up
(275494, 'spell_dummyfix_rogue_apprentice_of_shadows'),
(980048, 'spell_dummyfix_rogue_apprentice_of_shadows'),
-- Shadow of Death: Shadowstep arms the next Ambush / Ravage (+75% as Shadow, 272815)
(272816, 'spell_dummyfix_rogue_shadow_of_death'),
-- Swift Shadows: Ambush / Deadly Throw / Ravage on a Shadow Marked target reset Shadowstep
(272814, 'spell_dummyfix_rogue_swift_shadows'),
-- Bloody Resets: Hemorrhage / Ghostly Strike roll Sword and Board
(276300, 'spell_dummyfix_rogue_bloody_resets'),
-- Insatiable Blood: Hunger for Blood -1 sec cooldown per bleed on the target; Favour of the Soulflayer (275865) /
-- Blood for the Blood God (983070): Hunger for Blood uses up Bathe in Blood to trigger Favour
(51662, 'spell_dummyfix_rogue_hunger_for_blood'),
(1151662, 'spell_dummyfix_rogue_hunger_for_blood'),
(1251662, 'spell_dummyfix_rogue_hunger_for_blood'),
-- Cobra Venom (WCR Expunge): expunged at 3 stacks or on death (1584004)
(1584002, 'spell_dummyfix_rogue_cobra_venom'),
-- Relentless: Eviscerate's hit dealt again for 80% by 986053
(986052, 'spell_dummyfix_rogue_relentless'),
-- Sinister Finisher (WCR): the next Eviscerate hits one more nearby enemy for 15%
(1180391, 'spell_dummyfix_rogue_sinister_finisher'),
-- Remorseless Attacks capstone: Slice and Dice refreshed to its 5 combo point duration
(14148, 'spell_dummyfix_rogue_remorseless_attacks'),
-- Massacre talent: a killing blow on an experience / honor target takes 10 sec off Killing Spree (rule below)
(283139, 'spell_ascension_mystic_enchant_proc'),
-- Aether / Shadow / Dawn / Cinder / Glacial / Lightning Rupture: Rupture's (AP + SP) * 0.0039 * cp * cp tick bonus
-- (ComboPointPowerSquare set in the Contracts), as stock Rupture's chain binding (-1943)
(904960, 'spell_rog_rupture'), (904961, 'spell_rog_rupture'), (904962, 'spell_rog_rupture'), (904963, 'spell_rog_rupture'),
(904964, 'spell_rog_rupture'), (904965, 'spell_rog_rupture'), (904966, 'spell_rog_rupture'), (904967, 'spell_rog_rupture'),
(904968, 'spell_rog_rupture'),
(904980, 'spell_rog_rupture'), (904981, 'spell_rog_rupture'), (904982, 'spell_rog_rupture'), (904983, 'spell_rog_rupture'),
(904984, 'spell_rog_rupture'), (904985, 'spell_rog_rupture'), (904986, 'spell_rog_rupture'), (904987, 'spell_rog_rupture'),
(904988, 'spell_rog_rupture'),
(907000, 'spell_rog_rupture'), (907001, 'spell_rog_rupture'), (907002, 'spell_rog_rupture'), (907003, 'spell_rog_rupture'),
(907004, 'spell_rog_rupture'), (907005, 'spell_rog_rupture'), (907006, 'spell_rog_rupture'), (907007, 'spell_rog_rupture'),
(907008, 'spell_rog_rupture'),
(907020, 'spell_rog_rupture'), (907021, 'spell_rog_rupture'), (907022, 'spell_rog_rupture'), (907023, 'spell_rog_rupture'),
(907024, 'spell_rog_rupture'), (907025, 'spell_rog_rupture'), (907026, 'spell_rog_rupture'), (907027, 'spell_rog_rupture'),
(907028, 'spell_rog_rupture'),
(907040, 'spell_rog_rupture'), (907041, 'spell_rog_rupture'), (907042, 'spell_rog_rupture'), (907043, 'spell_rog_rupture'),
(907044, 'spell_rog_rupture'), (907045, 'spell_rog_rupture'), (907046, 'spell_rog_rupture'), (907047, 'spell_rog_rupture'),
(907048, 'spell_rog_rupture'),
(907060, 'spell_rog_rupture'), (907061, 'spell_rog_rupture'), (907062, 'spell_rog_rupture'), (907063, 'spell_rog_rupture'),
(907064, 'spell_rog_rupture'), (907065, 'spell_rog_rupture'), (907066, 'spell_rog_rupture'), (907067, 'spell_rog_rupture'),
(907068, 'spell_rog_rupture');

DELETE FROM `spell_proc` WHERE `SpellId` IN (285279, 1589466, 283833, 977856, 285111, 983110, 277924, 285017, 284148, 979106,
    275094, 285477, 986038, 1180000, 272816, 272814, 276300, 986052, 1180391, 914156, 283139);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- finisher procs: any own spell cast; the script keeps finishing moves and rolls per combo point before they are spent
(285279, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(1589466, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(283833, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(977856, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(285111, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(983110, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(277924, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(285017, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(284148, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(979106, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(275094, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(285477, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
(986038, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x1, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Shadow Blades: own melee spell damage landing (the script keeps direct combo point builders)
(1180000, 0, 0, 0x0, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Shadow of Death: own spells, cast (Shadowstep arms) and hit (Ambush / Ravage damage)
(272816, 0, 0, 0x0, 0x0, 0x0, 0x15550, 0x7, 0x3, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Swift Shadows: own melee / ranged spell damage landing (the script keeps Ambush / Deadly Throw / Ravage on a marked target)
(272814, 0, 0, 0x0, 0x0, 0x0, 0x110, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Bloody Resets: own melee spell damage landing (the script keeps Hemorrhage / Ghostly Strike and rolls the talent)
(276300, 0, 8, 0x0, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Relentless effect 1 / Sinister Finisher: Eviscerate (0x20000) damage landing
(986052, 0, 8, 0x20000, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
(1180391, 0, 8, 0x20000, 0x0, 0x0, 0x10, 0x1, 0x2, 0x0, 0x0, 0, 0, 100, 0, 0),
-- Ruthlessness enchant: 20% on Rogue melee finishing moves (14156's finisher mask), at the finish phase where the
-- finisher's target receives the combo point (Spell::_handle_finish_phase)
(914156, 0, 8, 0x120000, 0x8, 0x30000000, 0x10, 0x7, 0x4, 0x0, 0x0, 0, 0, 20, 0, 0),
-- Massacre talent: killing blows
(283139, 0, 0, 0x0, 0x0, 0x0, 0x2, 0x0, 0x0, 0x0, 0x0, 0, 0, 100, 0, 0);

DELETE FROM `coa_mystic_enchant_proc` WHERE `enchant_spell` = 283139;
INSERT INTO `coa_mystic_enchant_proc` (`enchant_spell`, `effect`, `rule`, `event`, `school_mask`, `spells`, `chance`, `cooldown_ms`, `requires_aura`, `target_aura`, `conditions`, `consume_aura`, `trigger_spells`, `amount_pct`, `chance_per_combo`, `comment`) VALUES
(283139, 0, 0, 'kill', 0, '', 100, 0, '', '', '', '', '283134', 0, 0, 'Massacre (talent 283139): killing an experience / honor target takes 10 sec off Killing Spree (283134)');
