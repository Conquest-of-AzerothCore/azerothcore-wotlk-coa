-- Free-pick Hero Warrior tree: abilities and talents doing what their Ascension tooltips say.
--
-- Enrage 12317-13048: "after using Bloodrage, Berserker Rage or Recklessness"; the final rank also "from being struck
-- by a damaging attack while below 50% health". Stock procs from every direct hit taken, and ranks 4-5 carry no
-- proc flags at all. The proc row now listens for the three casts and for hits taken; the script admits the casts
-- and, on the final rank only, hits below 50% health.
DELETE FROM `spell_script_names` WHERE `spell_id` = -12317 AND `ScriptName` IN ('spell_gen_proc_from_direct_damage', 'aura_hero_warrior_enrage');
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-12317, 'aura_hero_warrior_enrage');
DELETE FROM `spell_proc` WHERE `SpellId` = -12317;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-12317, 0, 0, 0, 0, 0, 0x000226A8, 0, 2, 0, 0, 0, 0, 0, 0, 0);

-- Dance of Death 954192-954194: "Increases your critical strike chance when your health is below 75%". The periodic
-- trigger applied the crit buff at any health.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_warrior_dance_of_death';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(954192, 'aura_hero_warrior_dance_of_death'),
(954193, 'aura_hero_warrior_dance_of_death'),
(954194, 'aura_hero_warrior_dance_of_death');

-- Raging Blow 954836 and Raging Lunge: "Becoming Enraged enables one use of Raging Blow. You can store up to 2
-- charges." Nothing granted Rage! 954881, so neither could ever be cast. Becoming enraged now grants a charge (the
-- UnitScript); each cast spends one.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hero_warrior_spend_rage_charge';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(954836, 'spell_hero_warrior_spend_rage_charge'),
(286391, 'spell_hero_warrior_spend_rage_charge'),
(980705, 'spell_hero_warrior_spend_rage_charge'),
(980708, 'spell_hero_warrior_spend_rage_charge'),
(980709, 'spell_hero_warrior_spend_rage_charge'),
(980710, 'spell_hero_warrior_spend_rage_charge'),
(980711, 'spell_hero_warrior_spend_rage_charge'),
(980712, 'spell_hero_warrior_spend_rage_charge'),
(980713, 'spell_hero_warrior_spend_rage_charge');

-- Hamstring 1715: "Attack the enemy for {AP*0.2+1} damage". No attack power coefficient, so it hit for 1.
DELETE FROM `spell_bonus_data` WHERE `entry` = 1715;
INSERT INTO `spell_bonus_data` (`entry`, `direct_bonus`, `dot_bonus`, `ap_bonus`, `ap_dot_bonus`, `comments`) VALUES
(1715, 0, 0, 0.2, 0, 'Warrior - Hamstring');

-- Juggernaut 64976 / 864976: "Following a Charge or Heroic Leap". The proc row was keyed to rank 1 only, so the
-- Ascension rank 2 used its bare DBC proc flags with no Charge mask.
DELETE FROM `spell_proc` WHERE `SpellId` IN (64976, -64976);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-64976, 0, 4, 1, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0);

-- Commanding Presence 12318/12857: "Battle Shout increases your Strength ... and Commanding Shout increases your
-- Stamina ... for 3600 sec". No proc flags, so neither shout ever applied Battle Presence or Commanding Presence.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_warrior_commanding_presence';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-12318, 'aura_hero_warrior_commanding_presence');
DELETE FROM `spell_proc` WHERE `SpellId` = -12318;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-12318, 0, 4, 0x00010000, 0x00000080, 0, 0x00004400, 0, 2, 0, 0, 0, 0, 0, 0, 0);

-- Improved Victory Rush 12324-12877: "a 33/66/100% chance when you parry ... once every 12 seconds". With no proc row
-- ranks 2-3 procced from any hit taken with no cooldown, and rank 1 has no trigger effect at all.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_warrior_improved_victory_rush';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(12324, 'aura_hero_warrior_improved_victory_rush');
DELETE FROM `spell_proc` WHERE `SpellId` = -12324;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-12324, 0, 0, 0, 0, 0, 0x00000028, 0, 2, 0x00000020, 0, 0, 0, 0, 12000, 0);

-- Improved Berserker Stance 29759-29761: "This effect is doubled while Enrage is active." The bonus never doubled.
-- The capstone ("Raging Blow increases the duration of your Recklessness by 1 second") had no proc flags; Raging Blow's
-- cast script now casts 986820.
DELETE FROM `spell_proc` WHERE `SpellId` = 29761;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'aura_hero_warrior_improved_berserker_stance';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(-29759, 'aura_hero_warrior_improved_berserker_stance');

-- Bloodsurge 46913-46915: "Damaging spells and abilities have a 33/66/100% chance ... once every 6 sec". The stock row
-- listened only for Heroic Strike, Bloodthirst and Whirlwind, with no cooldown.
DELETE FROM `spell_proc` WHERE `SpellId` = -46913;
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`, `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`, `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`) VALUES
(-46913, 0, 0, 0, 0, 0, 0x00010010, 1, 2, 0, 0, 0, 0, 0, 6000, 0);

-- Bloodsurge buff 46916: "Your next Bloodthirst triggers no cooldown". Its cooldown modifier is 0 and nothing spent the
-- buff (the stock row is keyed to Slam); Bloodthirst now clears its cooldown and spends the buff.
DELETE FROM `spell_proc` WHERE `SpellId` = 46916;
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_hero_warrior_bloodsurge_bloodthirst';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(23881, 'spell_hero_warrior_bloodsurge_bloodthirst');
