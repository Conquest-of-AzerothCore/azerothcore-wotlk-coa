-- Unbroken 707407 (Witch Hunter): "Taking damage increases your attack power, up to 20% of maximum health. Increased
-- further against Demons and Undead. This degrades slowly over time, and while out of combat."
-- Its three Spell.dbc effects are passive dummy auras (BasePoints 325/150/75, MiscValue 5/10/20, MiscValueB 10/5/50)
-- and its row carries ProcFlags 0, so the core never generated a proc from it and no spell_proc row existed. The
-- bonus AP was therefore unreachable: the client showed the talent and the two AP buffs (707487, AP and AP versus
-- Demons/Undead with MiscValue 36) had nothing casting them.
-- ProcFlags 139944: taken melee and ranged auto attacks, melee and ranged abilities, and harmful spells; no periodic
-- ticks, so damage-over-time cannot stack it. Chance 0 keeps the record's own ProcChance (100). SpellPhaseMask 0, as
-- the TAKEN_* flags must not be limited to the hit phase.
-- aura_ascension_witch_hunter_unbroken sets 707487 to the full 20% of maximum health cap on the first proc, then walks
-- the amount back down through the DBC decay tiers, each step removing that tier's percentage of the cap, and refreshes
-- the buff on every tick.
DELETE FROM `spell_proc` WHERE `SpellId` = 707407;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (707407, 0, 0, 0, 0, 0, 139944, 1, 0, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 707407 AND `ScriptName` = 'aura_ascension_witch_hunter_unbroken';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES (707407, 'aura_ascension_witch_hunter_unbroken');
