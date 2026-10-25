-- Freepick (Dawnrise) Rogue tree: abilities and talents match their tooltips.

-- Shuriken Toss 954835/955223-955228: "{525+0+SP*0.375+RAP*0.4}" (ranged attack power: AscensionHeroRogue sets
-- UseRangedAttackPowerForDamage). No row: the toss dealt its base damage only.
DELETE FROM `spell_bonus_data` WHERE `entry` IN (954835, 955223, 955224, 955225, 955226, 955227, 955228);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(954835, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955223, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955224, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955225, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955226, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955227, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss'),
(955228, 0.375, 0, 0.4, 0, 'Rogue - Shuriken Toss');

-- Crimson Tempest 954809/954883-954889: the bleed's (AP+SP) part (the hit's is in the core with Eviscerate's).
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_rogue_crimson_tempest_bleed';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(954809, 'aura_hero_rogue_crimson_tempest_bleed'),
(954883, 'aura_hero_rogue_crimson_tempest_bleed'),
(954884, 'aura_hero_rogue_crimson_tempest_bleed'),
(954885, 'aura_hero_rogue_crimson_tempest_bleed'),
(954886, 'aura_hero_rogue_crimson_tempest_bleed'),
(954887, 'aura_hero_rogue_crimson_tempest_bleed'),
(954888, 'aura_hero_rogue_crimson_tempest_bleed'),
(954889, 'aura_hero_rogue_crimson_tempest_bleed');

-- Blade Twisting 31124/31126: "Shiv and Grappling Hook Follow-Up have a 50%/100% chance to Daze the target". Rank 1
-- carries no proc flags in Spell.dbc; the script limits both ranks to the two named attacks.
DELETE FROM `spell_proc` WHERE `SpellId` = -31124;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-31124, 0, 0, 0, 0, 0, 0x00000010, 1, 2, 0, 0, 0, 0, 0, 0, 0);
DELETE FROM `spell_script_names` WHERE `spell_id` = -31124 AND `ScriptName` = 'aura_hero_rogue_blade_twisting';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-31124, 'aura_hero_rogue_blade_twisting');

-- Improved Kick 13754/13867: "Gives your Kick ability a 50%/100% chance to silence the target". Rank 1 carries no proc
-- flags in Spell.dbc; Kick is a melee-class spell.
DELETE FROM `spell_proc` WHERE `SpellId` = -13754;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-13754, 0, 8, 0x00000010, 0, 0, 0x00000010, 0, 2, 0, 0, 0, 0, 0, 0, 0);

-- Malice 14142 capstone: "You gain 5 Energy when your Garrote, Rupture or Crimson Tempest deal damage." Spell.dbc
-- carries no proc flags: Garrote and Rupture ticks, Crimson Tempest's hit and bleed.
DELETE FROM `spell_proc` WHERE `SpellId` = 14142;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(14142, 0, 8, 0x00100100, 0, 0x20000000, 0x00040010, 1, 2, 0, 0, 0, 0, 0, 0, 0);

-- Unfair Advantage 51672/51674: "Whenever you dodge or parry an attack". The stock row answers dodges only.
DELETE FROM `spell_proc` WHERE `SpellId` = -51672;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-51672, 0, 0, 0, 0, 0, 0, 0, 0, 0x00000030, 0, 0, 0, 0, 1000, 0);

-- Slaughter from the Shadows 51708-51710: "Damaging spells and abilities have a 33%/66%/100% chance to reduce the
-- cooldown of your Shadow Dance". Spell.dbc's class mask names Backstab and Hemorrhage only; any damaging melee,
-- ranged or magic spell now procs it.
DELETE FROM `spell_proc` WHERE `SpellId` = -51708;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-51708, 0, 0, 0, 0, 0, 0x00010110, 1, 2, 0, 0, 0, 0, 0, 0, 0);

-- Killing Spree's teleport 57840: Massacre only with the Massacre Mystic Enchant 415001.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hero_rogue_killing_spree_massacre';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(57840, 'spell_hero_rogue_killing_spree_massacre');
