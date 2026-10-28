-- Runemaster Ley Power (801096): one Harvested Ley Energy (803258) stack per enemy within 20 yd; each stack adds 10%
-- of the caster's damage as Arcane damage (803282). Melee attacks and abilities grant Harnessed Leylines (804316).
DELETE FROM `spell_proc` WHERE `SpellId` IN (801096, 803258);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(801096, 0, 0, 0, 0, 0, 0x00000014, 0x1, 0x2, 0, 0, 0x3, 0, 0, 0, 0),
(803258, 0, 0, 0, 0, 0, 0x00051154, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (801096, 803258) AND `ScriptName` IN
    ('spell_ascension_runemaster_ley_power', 'aura_ascension_runemaster_harvested_ley_energy');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(801096, 'spell_ascension_runemaster_ley_power'),
(803258, 'aura_ascension_runemaster_harvested_ley_energy');
