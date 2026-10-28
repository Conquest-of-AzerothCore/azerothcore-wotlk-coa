-- Freepick (Dawnrise) Mage tree: abilities and talents match their tooltips.

-- Talents whose proc auras carry no proc flags in Spell.dbc (and no spell_proc row): they never procced.
DELETE FROM `spell_proc` WHERE `SpellId` IN (828574, 828575, 828576, 11071, 12496, 12497, 31682, 31683, 31684, 44442,
    -44442, 44443, 12519, 835583, 11094, -11094, 13043, 31638, -31638, 31639);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Power Surge: "Your direct magic damage has a 33/66/100% chance to grant you a Power Surge"
(828574, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(828575, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(828576, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Frostbite: "Dealing direct frost damage has 5/10/15% chance to freeze the target"
(11071, 16, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(12496, 16, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(12497, 16, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Empowering Frostbolt: "After casting Frostbolt"
(31682, 0, 3, 0x00000020, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(31683, 0, 3, 0x00000020, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(31684, 0, 3, 0x00000020, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Firestarter: "Casting direct damaging Fire spells or abilities that have a cooldown" (the script checks the
-- cooldown); the old row named Dragon's Breath and no proc flags
(44442, 4, 0, 0, 0, 0, 0x00010110, 1, 2, 0, 0, 0, 0, 0, 1000, 0),
(44443, 4, 0, 0, 0, 0, 0x00010110, 1, 2, 0, 0, 0, 0, 0, 1000, 0),
-- Frost Channeling capstone: "Killing an enemy that yields experience or honor with Frost damage"
(12519, 16, 0, 0, 0, 0, 0x00050000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Spell Power capstone: "Dealing direct critical damage with a spell while your mana is below 50% ... once every 30
-- seconds"
(835583, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0x00000002, 0, 0, 0, 0, 30000, 0),
-- Molten Shields: "Your Fire Ward, Frost Ward, Arcane Ward and Shadow Ward spells have a 50/100% chance to reflect"
(11094, 0, 0, 0, 0, 0, 0x00004000, 4, 2, 0, 0, 0, 0, 0, 0, 0),
(13043, 0, 0, 0, 0, 0, 0x00004000, 4, 2, 0, 0, 0, 0, 0, 0, 0),
-- Playing with Fire: "Dealing direct magic damage" (Explosive Shot is a ranged-class Fire ability the tooltip names)
(31638, 0, 0, 0, 0, 0, 0x00010100, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(31639, 0, 0, 0, 0, 0, 0x00010100, 1, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_hero_mage_deep_freeze', 'aura_hero_mage_empowering_frostbolt',
    'aura_hero_mage_firestarter', 'aura_hero_mage_frost_channeling', 'aura_hero_mage_spell_power',
    'aura_hero_mage_molten_shields', 'aura_hero_mage_playing_with_fire', 'aura_hero_mage_power_surge_mana_shield');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Deep Freeze: Spell.dbc leaves each rank a dummy; the stun (844572) or, on stun-immune creatures, the damage
(44572, 'spell_hero_mage_deep_freeze'),
(44665, 'spell_hero_mage_deep_freeze'),
(44666, 'spell_hero_mage_deep_freeze'),
(44667, 'spell_hero_mage_deep_freeze'),
(44668, 'spell_hero_mage_deep_freeze'),
(31682, 'aura_hero_mage_empowering_frostbolt'),
(31683, 'aura_hero_mage_empowering_frostbolt'),
(31684, 'aura_hero_mage_empowering_frostbolt'),
(44442, 'aura_hero_mage_firestarter'),
(44443, 'aura_hero_mage_firestarter'),
(12519, 'aura_hero_mage_frost_channeling'),
(835583, 'aura_hero_mage_spell_power'),
(11094, 'aura_hero_mage_molten_shields'),
(13043, 'aura_hero_mage_molten_shields'),
(31638, 'aura_hero_mage_playing_with_fire'),
(31639, 'aura_hero_mage_playing_with_fire'),
-- Power Surge's "next Mana Shield" bonus
(-1463, 'aura_hero_mage_power_surge_mana_shield');
