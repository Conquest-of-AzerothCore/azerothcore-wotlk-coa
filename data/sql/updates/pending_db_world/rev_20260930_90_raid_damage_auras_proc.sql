-- Raid damage auras: party and raid members in range "deal <coefficient> additional damage as <school> damage when
-- they deal direct damage". Each ability hands them a proc-trigger-with-value aura whose Spell.dbc row carries no
-- proc flags and had no spell_proc row, so the extra damage never happened:
--   Clanlord's Totem 804737 (Barbarian)      -> 560530 -> 560529 Frost,       $AP*0.35
--   Command Aura 524600 (Ranger)             -> 537248 -> 537249 Stormstrike, $RAP*0.35
--   Purify Blood 680679 (Bloodmage)          -> 520839 -> 573273 Shadow,      $sps*.6
--   Celestial Resonance 801130 (Starcaller)  -> 520929 -> 573309 Arcane,      $spa*.7
-- ProcFlags 69972: melee and ranged auto attacks, melee and ranged abilities, harmful spells; no periodic ticks.
-- This replaces the melee/ranged-only 537248 row from rev_20260928_82_ranger_command_aura_proc, so Command Aura
-- also fires on allied spell damage like the other three. Chance 0 keeps each record's own ProcChance (100).
-- aura_ascension_raid_damage_aura sets the amount from the caster's stat and has the ally cast the damage.
-- spell_ascension_raid_damage_aura skips allies that already have Exhaustion (573255), as the tooltips state.
DELETE FROM `spell_proc` WHERE `SpellId` IN (560530, 537248, 520839, 520929);
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (560530, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 0, 0, 0),
  (537248, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 0, 0, 0),
  (520839, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 0, 0, 0),
  (520929, 0, 0, 0, 0, 0, 69972, 1, 2, 0, 0, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names`
WHERE (`spell_id` IN (560530, 537248, 520839, 520929) AND `ScriptName` = 'aura_ascension_raid_damage_aura')
   OR (`spell_id` IN (804737, 524600, 680679, 801130) AND `ScriptName` = 'spell_ascension_raid_damage_aura');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(560530, 'aura_ascension_raid_damage_aura'),
(537248, 'aura_ascension_raid_damage_aura'),
(520839, 'aura_ascension_raid_damage_aura'),
(520929, 'aura_ascension_raid_damage_aura'),
(804737, 'spell_ascension_raid_damage_aura'),
(524600, 'spell_ascension_raid_damage_aura'),
(680679, 'spell_ascension_raid_damage_aura'),
(801130, 'spell_ascension_raid_damage_aura');
