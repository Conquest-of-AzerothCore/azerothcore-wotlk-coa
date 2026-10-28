-- Freepick (Dawnrise) Warlock tree: abilities and talents match their tooltips.

-- Ascension's hybrid formulas: the tooltips scale with spell power AND attack power; the rows carried stock WotLK
-- spell-power-only coefficients (Chaos Bolt 0.714, Soul Fire 1.15, Shadowburn 0.4286, Dark Pact 0.96) and no AP.
-- Chaos Bolt 50796-59172: "{1643+0+SP*0.69+AP*0.4485}"; Soul Fire 6353-47825: "{1323+0+SP*0.69+AP*0.45}";
-- Shadowburn 17877-47827: "{775+SP*0.3748+AP*0.2436}"; Dark Pact 18220-59092: "{1200+SP*0.35+AP*0.2275}".
DELETE FROM `spell_bonus_data` WHERE `entry` IN (50796, 50865, 50866, 59170, 59171, 59172, 18220, 18221, 18937, 18938, 27265, 59092, 17877, 17888, 18867, 18868, 18869, 18870, 18871, 27263, 30546, 47826, 47827, 6353, 6367, 6368, 17924, 27211, 30545, 47824, 47825);
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(50796, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(50865, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(50866, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(59170, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(59171, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(59172, 0.69, 0, 0.4485, 0, 'Warlock - Chaos Bolt'),
(18220, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(18221, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(18937, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(18938, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(27265, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(59092, 0.35, 0, 0.2275, 0, 'Warlock - Dark Pact'),
(17877, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(17888, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(18867, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(18868, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(18869, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(18870, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(18871, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(27263, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(30546, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(47826, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(47827, 0.3748, 0, 0.2436, 0, 'Warlock - Shadowburn'),
(6353, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(6367, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(6368, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(17924, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(27211, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(30545, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(47824, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire'),
(47825, 0.69, 0, 0.45, 0, 'Warlock - Soul Fire');

-- Talents whose proc auras carry no proc flags in Spell.dbc
DELETE FROM `spell_proc` WHERE `SpellId` IN (-17931, 17931, 30299, -30299, 818219);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Improved Shadowburn 17931-17933: "Dealing damage with direct Shadow spells or abilities has a 10/20/30% chance"
(-17931, 32, 0, 0, 0, 0, 0x00010010, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Nether Protection 30299-30302: "when being hit with a spell or taking periodic spell damage ... once every 4 sec".
-- The old rank-1-only row and ranks 1-2 carried no proc flags; rank 3 had them.
(-30299, 126, 0, 0, 0, 0, 0x000A0000, 1, 2, 0, 0, 0, 0, 0, 4000, 0),
-- Grim Reach capstone: "Dealing periodic Shadow damage to an enemy within melee range has a 33% chance"
(818219, 32, 0, 0, 0, 0, 0x00040000, 1, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_warlock_grim_reach';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(818219, 'aura_hero_warlock_grim_reach');
