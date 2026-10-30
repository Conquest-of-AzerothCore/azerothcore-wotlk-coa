-- Reborn namesakes of stock proc spells keep no proc data of their own: Seal of Light 1120165 and Shamanistic Rage
-- 1130823 proc at their Spell.dbc chance, 0; Static Shock 1151525-1151527 (a proc trigger aura where stock has a dummy; the stock script now takes either)
-- and Improved Mind Blast's proc effect have no proc entry at all. Each takes its stock spell's row; Static Shock's
-- procs per minute are its tooltip's 1.5, and Improved Mind Blast procs only in Shadowform, as its tooltip says.
DELETE FROM `spell_proc` WHERE `SpellId` IN (1120165, 1130823, 1151525, 1151526, 1151527, 1115273, 1115312, 1115313,
1115314, 1115316);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
`SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
`DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(1120165, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 10, 0, 0, 0),
(1130823, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 18, 0, 0, 0),
(1151525, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 1.5, 0, 0, 0),
(1151526, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 1.5, 0, 0, 0),
(1151527, 0, 0, 0, 0, 0, 0, 0x1, 0x2, 0, 0, 0, 1.5, 0, 0, 0),
(1115273, 0, 6, 0x00002000, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(1115312, 0, 6, 0x00002000, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(1115313, 0, 6, 0x00002000, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(1115314, 0, 6, 0x00002000, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0),
(1115316, 0, 6, 0x00002000, 0, 0, 0x10000, 0x1, 0x2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` IN (1120165, 1130823, 1151525, 1151526, 1151527, 1115273, 1115312,
1115313, 1115314, 1115316);
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(1120165, 'spell_pal_seal_of_light'),
(1130823, 'spell_sha_shamanistic_rage'),
(1151525, 'spell_sha_static_shock'),
(1151526, 'spell_sha_static_shock'),
(1151527, 'spell_sha_static_shock'),
(1115273, 'spell_ascension_reborn_improved_mind_blast'),
(1115312, 'spell_ascension_reborn_improved_mind_blast'),
(1115313, 'spell_ascension_reborn_improved_mind_blast'),
(1115314, 'spell_ascension_reborn_improved_mind_blast'),
(1115316, 'spell_ascension_reborn_improved_mind_blast');
