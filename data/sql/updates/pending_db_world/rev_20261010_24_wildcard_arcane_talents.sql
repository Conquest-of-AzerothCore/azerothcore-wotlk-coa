-- Power Overwhelming: Spell.dbc limits its proc to family flag 0x800 (Arcane Missiles), whose damage comes from a
-- triggered missile that never carries that flag, so it never procs. Its tooltip names any direct damage from spells and
-- abilities that trigger the global cooldown; the script checks the global cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = 283578;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(283578, 0, 0, 0, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0);

-- Barrage Overload: consuming Missile Barrage grants a stack, and Arcane Barrage unleashes one bolt per stack.
-- Unstable Evocation: completing the channel blasts nearby enemies (284295).
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_wildcard_power_overwhelming',
    'aura_wildcard_missile_barrage_overload', 'spell_wildcard_arcane_barrage_overload', 'aura_wildcard_unstable_evocation');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(283578, 'aura_wildcard_power_overwhelming'),
(44401, 'aura_wildcard_missile_barrage_overload'),
(-44425, 'spell_wildcard_arcane_barrage_overload'),
(284298, 'aura_wildcard_unstable_evocation');
