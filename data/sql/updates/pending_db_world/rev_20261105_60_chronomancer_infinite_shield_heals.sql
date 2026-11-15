-- Infinite Shield (520457): "Each time they take damage, they will be healed for ... and lose 1 charge. Can only
-- occur once per sec." The record has ProcFlags 0 and no spell_proc row existed, so the aura never procs. Proc on
-- any damage taken (PROC_FLAG_TAKEN_DAMAGE) with the tooltip's 1 s internal cooldown; the 10 charges match the
-- C++ record patch. The script casts the heal 520458 from the aura caster onto the shielded unit, as the generic
-- trigger would cast it from the shielded unit at the attacker. The heal's spell power coefficient is the 25% the
-- spell's own tooltip and the Ascension snapshot give (190 + 25% SP); 520458's hidden text says 28%.
DELETE FROM `spell_script_names` WHERE `spell_id` = 520457 AND `ScriptName` = 'aura_ascension_infinite_shield';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(520457, 'aura_ascension_infinite_shield');

DELETE FROM `spell_proc` WHERE `SpellId` = 520457;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(520457, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 100, 1000, 10);

DELETE FROM `spell_bonus_data` WHERE `entry` = 520458;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(520458, 0.25, 0, 0, 0, 'Infinite Shield heal');
