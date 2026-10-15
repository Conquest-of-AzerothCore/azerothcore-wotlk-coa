-- Legacy of Rexxar (#456): the copied record distributes its Primal Shred proc aura to the pet,
-- but all three critical-strike proc tables were missing. Link the authored Wildclaw/Rylak helpers
-- to the talent so their lifetime follows learning, removal and native pet aura propagation.
DELETE FROM `spell_linked_spell` WHERE `spell_trigger` = 800184 AND `spell_effect` IN (560971, 560972) AND `type` = 2;
INSERT INTO `spell_linked_spell` (`spell_trigger`, `spell_effect`, `type`, `comment`) VALUES
(800184, 560971, 2, 'Legacy of Rexxar: Huffer critical-strike listener'),
(800184, 560972, 2, 'Legacy of Rexxar: Leokk critical-strike listener');

-- Primal Shred: pet periodic critical damage only; effect 0 is the owner's descriptive dummy.
-- Wildclaw: main-hand ranks (mask0 0x80000) and its off-hand helper (mask1 0x2).
-- Rylak's Bite: all ranks share mask2 0x40. Triggered off-hand damage retains native proc admission.
-- Misha's Rage: only white melee swings, with its authored once-per-second internal cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` IN (800184, 560971, 560972, 504227);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(800184, 0, 37, 0, 0, 32, 262144, 1, 2, 2, 2, 1, 0, 100, 0, 0),
(560971, 0, 37, 524288, 2, 0, 16, 1, 2, 2, 2, 0, 0, 100, 0, 0),
(560972, 0, 37, 0, 0, 64, 16, 1, 2, 2, 2, 0, 0, 100, 0, 0),
(504227, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 0, 100, 1000, 0);

-- The visible talent promises the authored helper base plus 12.5% AP; native procs retain Primalist credit.
DELETE FROM `spell_bonus_data` WHERE `entry` = 560975;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(560975, 0, 0, 0.125, 0, 'Primalist: Legacy of Rexxar - Misha additional physical damage');

-- These pet-cast bleeds have no rank chain. Snapshot the pet's native critical chance for all nine ranks.
DELETE FROM `spell_script_names` WHERE `spell_id` IN (504669, 504670, 504671, 504672, 504673, 504674, 504675, 504676, 504684) AND `ScriptName` = 'aura_ascension_primal_shred_critical';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(504669, 'aura_ascension_primal_shred_critical'),
(504670, 'aura_ascension_primal_shred_critical'),
(504671, 'aura_ascension_primal_shred_critical'),
(504672, 'aura_ascension_primal_shred_critical'),
(504673, 'aura_ascension_primal_shred_critical'),
(504674, 'aura_ascension_primal_shred_critical'),
(504675, 'aura_ascension_primal_shred_critical'),
(504676, 'aura_ascension_primal_shred_critical'),
(504684, 'aura_ascension_primal_shred_critical');
