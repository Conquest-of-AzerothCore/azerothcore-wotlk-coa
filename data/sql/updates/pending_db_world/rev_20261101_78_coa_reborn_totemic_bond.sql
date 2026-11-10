-- Reborn Totemic Bond (1182036-1182038) has no proc data and no script of its own: casting Stoneclaw Totem while
-- Earthen Guardian is up has the rank's chance to reduce damage taken (1182042), and a Searing or Magma Totem redirects
-- the rank's share of its threat to the shaman (1182039-1182041). The Stoneclaw chance is rolled by the script.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (1182036, 1182037, 1182038) AND `ScriptName` =
'spell_ascension_reborn_totemic_bond';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1182036, 'spell_ascension_reborn_totemic_bond'),
(1182037, 'spell_ascension_reborn_totemic_bond'),
(1182038, 'spell_ascension_reborn_totemic_bond');

DELETE FROM `spell_proc` WHERE `SpellId` IN (1182036, 1182037, 1182038);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1182036, 0, 11, 0x1018, 0, 0, 0x4400, 0x7, 0x4, 0, 0, 0x2, 0, 100, 0, 0),
(1182037, 0, 11, 0x1018, 0, 0, 0x4400, 0x7, 0x4, 0, 0, 0x2, 0, 100, 0, 0),
(1182038, 0, 11, 0x1018, 0, 0, 0x4400, 0x7, 0x4, 0, 0, 0x2, 0, 100, 0, 0);
