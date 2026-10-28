-- Runemaster talents whose Spell.dbc records carry ProcFlags 0: SpellMgr::LoadSpellProcs generates no entry for
-- them, so their SPELL_AURA_PROC_TRIGGER_SPELL effects never fire.
-- Power Overwhelming 707876 (#1042): casting Runeblade (family 38 mask2 0x40000) or Primordial Blast (mask1
-- 0x100000) rolls the record's 35% once per cast; a proc casts 560051 and 561055, which resets Runic Brand.
-- Ley Walker 500250 (#1096): casting Warpdagger (mask1 0x800000) or reactivating it as Warp (mask1 0x40), both
-- DmgClass NONE, casts 503734, which dispels root and snare effects from the Runemaster.
DELETE FROM `spell_proc` WHERE `SpellId` IN (707876, 500250);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(707876, 0, 38, 0, 1048576, 262144, 65552, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(500250, 0, 38, 0, 8388672, 0, 5120, 0, 1, 0, 0, 0, 0, 0, 0, 0);

-- 561055 names Runic Brand's first rank (712299); a Runemaster casting a higher rank keeps that rank's cooldown, so
-- the reset covers every rank of the chain. Turbulence 705575 (#1136) leaves a Turbulent Spiral 707153 every tick.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (561055, 705575) AND `ScriptName` IN
    ('spell_ascension_runemaster_power_overwhelming_reset', 'aura_ascension_runemaster_turbulence');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(561055, 'spell_ascension_runemaster_power_overwhelming_reset'),
(705575, 'aura_ascension_runemaster_turbulence');

-- Turbulent Spiral (707153): ${$707153m1+$707153ppl1+$AP*0.135} Nature damage every sec.
DELETE FROM `spell_bonus_data` WHERE `entry` = 707153;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(707153, 0, 0, 0, 0.135, 'Ascension Runemaster Turbulent Spiral - AP');
