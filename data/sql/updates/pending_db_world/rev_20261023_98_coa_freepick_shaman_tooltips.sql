-- Freepick (Dawnrise) Shaman tree: abilities and talents match their tooltips.

-- Talents whose proc auras carry no proc flags in Spell.dbc (and no spell_proc row): they never procced.
DELETE FROM `spell_proc` WHERE `SpellId` IN (-16040, 829000, -30664, -16578, 863372, -62097, -16259, 16288, 16305,
    30816, 30818, 30819, -30816, -30798);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
-- Reverberation 16040-16114: "When you deal damage with a Shaman Shock spell" (Earth, Flame, Frost Shock)
(-16040, 0, 11, 0x90100000, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Elemental Reach capstone: "direct damage Fire, Nature and Frost spells on targets further than 20 yards ... once
-- every 15 sec" (distance in aura_hero_shaman_elemental_reach)
(829000, 28, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 15000, 0),
-- Unrelenting Storm 30664-30666: "Your direct damaging Nature spells and abilities increase your haste"
(-30664, 8, 0, 0, 0, 0, 0x00010010, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Lightning Mastery 16578-16580: "Your Lightning Bolt, Chain Lightning and Thunderstorm criticals"
(-16578, 0, 11, 0x00000003, 0x00002000, 0, 0x00010000, 1, 2, 0x00000002, 0, 0, 0, 0, 0, 0),
-- Booming Echoes capstone: "Dealing damage with a Shaman Shock spell"
(863372, 0, 11, 0x90100000, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Shamanism 62097-62099: "when dealing Nature damage"
(-62097, 8, 0, 0, 0, 0, 0x00010010, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Enhancing Totems 16259/16295/52456: "Placing a totem" (aura_hero_shaman_enhancing_totems checks the totem slot)
(-16259, 0, 11, 0, 0, 0, 0x00004400, 7, 1, 0, 0, 0, 0, 0, 0, 0),
-- Improved Ghost Wolf capstone: "Using Ghost Wolf ... once every 20 seconds"
(16288, 0, 11, 0x00000800, 0, 0, 0x00004400, 7, 1, 0, 0, 0, 0, 0, 20000, 0),
-- Thundering Strikes capstone: "Dealing damage with spell have a chance ... once every 6 seconds"
(16305, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 6000, 0),
-- Dual Wield Specialization 30816-30819: "Your off-hand auto attacks have a chance". Spell.dbc gives a 0% chance and
-- no flags; each rank's third effect carries 3 / 6 / 9 (its base points), taken as the chance. Off hand only (script).
(30816, 0, 0, 0, 0, 0, 0x00000004, 0, 0, 0, 0, 0, 0, 3, 0, 0),
(30818, 0, 0, 0, 0, 0, 0x00000004, 0, 0, 0, 0, 0, 0, 6, 0, 0),
(30819, 0, 0, 0, 0, 0, 0x00000004, 0, 0, 0, 0, 0, 0, 9, 0, 0),
-- Empowered Stormstrike 30798/830798: "After casting Stormstrike your auto-attacks will deal an additional ..."
(-30798, 0, 11, 0, 0x01000010, 0, 0x00000010, 1, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_hero_shaman_elemental_reach', 'aura_hero_shaman_enhancing_totems',
    'aura_hero_shaman_dual_wield_specialization', 'spell_hero_shaman_earth_shield_heal', 'spell_hero_shaman_sundering');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
-- Sundering 760121-760399: the tooltip's (SP+AP)*0.5
(760121, 'spell_hero_shaman_sundering'),
(760396, 'spell_hero_shaman_sundering'),
(760397, 'spell_hero_shaman_sundering'),
(760398, 'spell_hero_shaman_sundering'),
(760399, 'spell_hero_shaman_sundering'),
(829000, 'aura_hero_shaman_elemental_reach'),
(-16259, 'aura_hero_shaman_enhancing_totems'),
(30816, 'aura_hero_shaman_dual_wield_specialization'),
(30818, 'aura_hero_shaman_dual_wield_specialization'),
(30819, 'aura_hero_shaman_dual_wield_specialization'),
-- Improved Earth Shield capstone (Earth Shield's heal)
(379, 'spell_hero_shaman_earth_shield_heal');
