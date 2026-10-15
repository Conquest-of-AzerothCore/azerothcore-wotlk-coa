-- Horn of Endurance 806359 emanates proc aura 560809, which triggers self heal 560808.
-- 560809 had no proc flags and no proc row, so the described healing proc never fired.
-- The tooltip promises a chance "when you cast a spell or ability, once every 2 seconds": the landed
-- done-spell masks of both damage classes, at the hit phase, 30% chance. Auto-attacks, taken damage,
-- kills and the Horn's own periodic Focus ticks are deliberately not proc events.
DELETE FROM `spell_proc` WHERE `SpellId` = 560809;
INSERT INTO `spell_proc` (`SpellId`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `Chance`, `Cooldown`) VALUES
(560809, 87312, 7, 2, 0, 0, 30, 2000);

-- The default trigger aims the heal at whatever the member cast at, so the heal must be cast on its owner.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_ascension_ranger_endurance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560809, 'aura_ascension_ranger_endurance');

-- 560808 promised "${$560808m1+$560808ppl1+$AP*0.1295}" but had no bonus row, so it healed its flat 2 with no attack power.
DELETE FROM `spell_bonus_data` WHERE `entry` = 560808;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(560808, 0, 0, 0.1295, 0, 'Local Ranger: Horn of Endurance explicit AP per the tooltip');
