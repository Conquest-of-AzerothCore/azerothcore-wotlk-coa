-- Fire Fire Fireball 283064: "After casting Fireball twice in combat, your third Fireball has its cast time increased
-- by 0.44 sec and fires an additional wave of Fireballs toward your target." Spell.dbc gives the passive and its stack
-- aura 283066 ProcFlags 0x10 (melee-class spells) and no family mask, so Sundering and Judgement built the stacks,
-- 283066 applied Carbon Buildup 283068 by itself, and no Fireball ever fired the wave (#6789). The passive now procs
-- on a Fireball cast (family 3, mask 0x1, magic damage class, cast phase); 283066 no longer procs on its own.
-- aura_hero_fire_fire_fireball counts two Fireballs in combat into 283066 and applies Carbon Buildup; the third
-- Fireball fires the wave (three 283069, as rank 4 414029 / 414030 describes it) and 283077 removes both auras.
DELETE FROM `spell_proc` WHERE `SpellId` IN (283064, 283066);
INSERT INTO `spell_proc` (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
    `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
    `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
(283064, 0, 3, 1, 0, 0, 65536, 7, 1, 0, 0, 0, 0, 100, 0, 0),
(283066, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0);

DELETE FROM `spell_script_names` WHERE `spell_id` = 283064 AND `ScriptName` = 'aura_hero_fire_fire_fireball';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES
(283064, 'aura_hero_fire_fire_fireball');
