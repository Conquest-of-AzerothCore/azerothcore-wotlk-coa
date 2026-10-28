-- rev_20261022_86_coa_windfury_custom_proc fixed Reborn Windfury Weapon rank 1's enchant trigger (1133757),
-- but every other Reborn Windfury Weapon rank's enchant (SpellItemEnchantment 10284/10525/11669/12636/13785/
-- 13786/13787, cloned from stock 284/525/1669/2636/3785/3786/3787) triggers spell 1133758 instead. That spell
-- had no spell_script_names/spell_proc row, so Spell::EffectEnchantItemTmp applies the temporary enchant (the
-- report's "appears to apply") but the SPELL_AURA_DUMMY it casts is never recognized as proccable, so the
-- extra-attack proc never fires (#8854). Clone stock Windfury's own trigger (33757), mirroring
-- rev_20261022_86's fix for 1133757.
-- Reborn Earthliving Weapon's only rank (spell 1151730, enchant 103345 cloned from stock 3345) triggers spell
-- 1151940, likewise missing both rows. Clone stock's twin-keyed -51940 row, the same way Earth Shield /
-- Lightning Overload / Frozen Power were cloned in rev_20261008_27_coa_reborn_shaman_spells.sql.
DELETE FROM `spell_script_names` WHERE (`spell_id`, `ScriptName`) IN
((1133758, 'spell_sha_windfury_weapon'), (-1151940, 'spell_sha_earthliving_weapon'));
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1133758, 'spell_sha_windfury_weapon'),
(-1151940, 'spell_sha_earthliving_weapon');

DELETE FROM `spell_proc` WHERE `SpellId` = 1133758;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT 1133758, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = 33757;

DELETE FROM `spell_proc` WHERE `SpellId` = -1151940;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
SELECT -1151940, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges` FROM `spell_proc` WHERE `SpellId` = -51940;
