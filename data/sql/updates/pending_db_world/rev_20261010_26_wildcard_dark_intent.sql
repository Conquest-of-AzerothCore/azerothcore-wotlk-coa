-- Dark Intent 275493: "Dealing damage with Sinister Strike, Eviscerate, Garrote, Rupture, Crimson Tempest, Shiv, Ambush
-- and Gloomblade now deals additional Shadow damage. If the ability critically strikes, the additional Shadow damage is
-- also a critical hit." Spell.dbc gives it only PROC_FLAG_DONE_PERIODIC, so Sinister Strike never procced it, and its
-- class mask covers four of the eight abilities. Melee abilities and periodic damage from all eight now proc it: Dark
-- Intent crit 275496 after a critical hit, Dark Intent non-crit 275503 otherwise.
DELETE FROM `spell_proc` WHERE `SpellId` = 275493;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(275493, 0, 8, 0x20120302, 0, 0xA0000000, 0x40010, 0x1, 0x2, 0, 0, 0, 0, 100, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_wildcard_dark_intent';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(275493, 'aura_wildcard_dark_intent');
