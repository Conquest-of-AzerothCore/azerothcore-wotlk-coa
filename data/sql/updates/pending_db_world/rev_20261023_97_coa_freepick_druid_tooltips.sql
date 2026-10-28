-- Freepick (Dawnrise) Druid tree: abilities and talents match their tooltips.

-- Capstones whose proc auras carry no proc flags in Spell.dbc
DELETE FROM `spell_proc` WHERE `SpellId` IN (816819, 16913);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Nature's Reach r3: "Your Nature non-periodic spells ... if hitting a target affected by Insect Swarm. This effect has
-- a 6 sec internal cooldown." (aura_hero_druid_natures_reach)
(816819, 8, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 6000, 0),
-- Vengeance r5: "Your direct Arcane and Nature criticals have a chance to attract a Vengeful Soul"
(16913, 0x48, 0, 0, 0, 0, 0x00010000, 1, 2, 0x00000002, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_hero_druid_natures_reach', 'aura_hero_druid_vengeful_soul');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(816819, 'aura_hero_druid_natures_reach'),
(816913, 'aura_hero_druid_vengeful_soul');

-- Rake r2 1826: "Rake the target for {(AP+SP)*0.01+17} bleed damage and an additional {30*3+AP*0.06*3} damage over 9
-- sec". Every other rank has the 0.01 / 0.06 attack power row; rank 2 had none.
DELETE FROM `spell_bonus_data` WHERE `entry` = 1826;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1826, 0, 0, 0.01, 0.06, 'Druid - Rake');
