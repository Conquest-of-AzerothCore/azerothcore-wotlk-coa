-- Freepick (Dawnrise) Priest tree: abilities and talents match their tooltips.

-- Improved Mind Blast 15273-15316: "Mind Blast also has a 20-100% chance to reduce all healing done to the target".
-- Spell.dbc gives the ranks 0x1000 / 0x400 / 0 proc flags, none of which Mind Blast (magic damage class) raises.
-- Surge of Light 33150/33154: the all-ranks row reads each rank's own flags, and rank 2 has none.
DELETE FROM `spell_proc` WHERE `SpellId` IN (-15273, -33150, 827790, 817323, 33225, 63506, -47580, 33215);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-15273, 0, 6, 0x00002000, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
(-33150, 0, 0, 0, 0, 0, 0x00014000, 3, 2, 2, 2, 0, 0, 0, 6000, 0),
-- Holy Reach capstone: "Directly healing or directly damaging a target further than 20 yards away ... once every 15
-- sec" (distance in aura_hero_priest_reach_capstone)
(827790, 0, 0, 0, 0, 0, 0x00014000, 3, 2, 0, 0, 0, 0, 0, 15000, 0),
-- Shadow Reach capstone: "Dealing direct magic damage to a target further than 20 yards away ... once every 15 sec"
(817323, 0, 0, 0, 0, 0, 0x00010000, 1, 2, 0, 0, 0, 0, 0, 15000, 0),
-- Shadow Power capstone: "Your Shadow and Holy periodic damage effects have a 30% chance"
(33225, 0x22, 0, 0, 0, 0, 0x00040000, 1, 2, 0, 0, 0, 0, 0, 0, 0),
-- Improved Flash Heal capstone: "Flash Heal casts reduce the cooldown of Inner Focus by 2 seconds"
(63506, 0, 6, 0x00000800, 0, 0, 0x00004000, 2, 2, 0, 0, 0, 0, 0, 0, 0),
-- Pain and Suffering 47580-47582: "Shadow channeled spells and Mind Blast casts ... refresh your Shadow Word: Pain".
-- The stock row names Mind Flay only; Mind Blast (0x2000) and Mind Sear (0x100000) added.
(-47580, 0, 6, 0x00002000, 0x00100000, 0x00000040, 0x00010000, 0, 2, 0, 0, 0, 0, 0, 0, 0),
-- Void-touched Mind r3 capstone: Mind Blast hits and Mind Flay's triggered ticks 58381
-- (aura_hero_priest_void_touched_mind)
(33215, 0, 6, 0x00802000, 0, 0, 0x00010000, 1, 2, 0, 2, 0, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `ScriptName` IN ('aura_hero_priest_reach_capstone', 'spell_hero_priest_halo_frozen_light',
    'aura_hero_priest_void_touched_mind', 'aura_hero_priest_void_eruption_buff');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(827790, 'aura_hero_priest_reach_capstone'),
(817323, 'aura_hero_priest_reach_capstone'),
-- Halo rank 1's heal grants the Cryotherapist's Lesser Frozen Light only to a Cryotherapist
(954875, 'spell_hero_priest_halo_frozen_light'),
(33215, 'aura_hero_priest_void_touched_mind'),
(760185, 'aura_hero_priest_void_eruption_buff');
