-- Warcraft Reborn Mystic Enchants with a scripted action (AscensionMysticEnchantScripts.cpp). The proc rule that
-- decides when each fires is in rev_20261018_90 (coa_mystic_enchant_proc); these bind the action scripts and give the
-- helper auras the proc data their tooltips describe.
DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('spell_ascension_mystic_renewed_through_absolution',
    'spell_ascension_mystic_atonement', 'spell_ascension_mystic_atonement_heal', 'spell_ascension_mystic_fury_of_the_wind', 'spell_ascension_mystic_elunes_fury',
    'spell_ascension_mystic_lightning_fangs', 'spell_ascension_mystic_demonic_whirl', 'spell_ascension_mystic_vampiric_death',
    'spell_ascension_mystic_savage_frenzy', 'spell_ascension_mystic_shattered_renewal',
    'spell_ascension_mystic_arcane_conduit_trigger', 'spell_ascension_mystic_water_nova',
    'spell_ascension_mystic_heavy_thunder_check', 'spell_ascension_mystic_blessing_of_the_divines',
    'spell_ascension_mystic_shield_masters_resolve', 'spell_ascension_mystic_cauterize');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1571422, 'spell_ascension_mystic_renewed_through_absolution'),
(1567777, 'spell_ascension_mystic_atonement'),
(1567779, 'spell_ascension_mystic_atonement_heal'),
(1567780, 'spell_ascension_mystic_atonement_heal'),
(1590417, 'spell_ascension_mystic_fury_of_the_wind'),
(1583363, 'spell_ascension_mystic_elunes_fury'),
(1180160, 'spell_ascension_mystic_lightning_fangs'),
(1180110, 'spell_ascension_mystic_demonic_whirl'),
(1180080, 'spell_ascension_mystic_vampiric_death'),
(1180330, 'spell_ascension_mystic_savage_frenzy'),
(1181000, 'spell_ascension_mystic_shattered_renewal'),
(1181434, 'spell_ascension_mystic_arcane_conduit_trigger'),
(1569696, 'spell_ascension_mystic_water_nova'),
(1181083, 'spell_ascension_mystic_heavy_thunder_check'),
(1571465, 'spell_ascension_mystic_blessing_of_the_divines'),
(1556002, 'spell_ascension_mystic_shield_masters_resolve'),
(1181410, 'spell_ascension_mystic_cauterize');

-- Shadow Funnel's Voidwalker aura (Void Nova) and Lightning Fangs' wolf charge proc on the wearer's melee auto
-- attacks; Shattered Renewal's Weakened Soul removal procs on a kill (its script checks experience/honor).
DELETE FROM `spell_proc` WHERE `SpellId` IN (1180901, 1180161, 1181000);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `ProcsPerMinute`,
    `Chance`, `Cooldown`, `Charges`) VALUES
(1180901, 0, 0, 0, 0, 0, 0x4, 0, 0, 0, 0, 0, 100, 0, 0),
(1180161, 0, 0, 0, 0, 0, 0x4, 0, 0, 0, 0, 0, 100, 0, 0),
(1181000, 0, 0, 0, 0, 0, 0x2, 0, 0, 0, 0, 0, 100, 0, 0);
