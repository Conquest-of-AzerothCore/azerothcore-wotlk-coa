-- Soulstone Lure (561376) summoned nothing at all.
--
-- Its only effect is SPELL_EFFECT_SUMMON of creature 557911, and that creature has no
-- creature_template row. Player::SummonCreature finds no template, so the cast goes through, the
-- cooldown starts and no lure ever appears.
--
-- The template follows the ones the other custom classes already use for a planted object the
-- player leaves behind - Spirit Link Idol (522106) and Cauldron Hidden Periodic (506011): faction
-- 35 so nothing attacks it by faction alone, type 11 (not specified), no movement, and a level
-- band that keeps it out of level scaling.
INSERT INTO `creature_template`
  (`entry`, `name`, `subname`, `gossip_menu_id`, `minlevel`, `maxlevel`, `faction`, `npcflag`,
   `speed_walk`, `speed_run`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`,
   `flags_extra`, `ScriptName`)
VALUES
  (557911, 'Soulstone Lure', NULL, 0, 80, 80, 35, 0, 1, 1.14286, 1, 0, 11, '', 0, 0, 'npc_ascension_reaper_soulstone_lure')
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`), `minlevel` = VALUES(`minlevel`), `maxlevel` = VALUES(`maxlevel`),
  `faction` = VALUES(`faction`), `npcflag` = VALUES(`npcflag`), `unit_class` = VALUES(`unit_class`),
  `unit_flags` = VALUES(`unit_flags`), `type` = VALUES(`type`), `AIName` = VALUES(`AIName`),
  `MovementType` = VALUES(`MovementType`), `flags_extra` = VALUES(`flags_extra`),
  `ScriptName` = VALUES(`ScriptName`);

-- 410144 is the Spirit Link Idol's model: a small planted object that reads as something left on
-- the ground rather than a creature standing on it.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 557911;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`) VALUES
(557911, 0, 410144, 1, 1);

-- "Enemies who attack the lure are horrified" is the second half, and it never fired either.
-- 561826 is the aura the lure carries: effect 1 is the periodic taunt 562313, effect 2 is a
-- SPELL_AURA_PROC_TRIGGER_SPELL for the Fear 561827, and its record has ProcTypeMask 0, so the
-- aura is built with no proc flags and nothing reaches the handler.
--
-- PROC_FLAG_TAKEN_DAMAGE triggers the fear when the lure takes damage.
DELETE FROM `spell_proc` WHERE `SpellId` = 561826;
INSERT INTO `spell_proc`
  (`SpellId`, `SchoolMask`, `SpellFamilyName`, `SpellFamilyMask0`, `SpellFamilyMask1`,
   `SpellFamilyMask2`, `ProcFlags`, `SpellTypeMask`, `SpellPhaseMask`, `HitMask`, `AttributesMask`,
   `DisableEffectsMask`, `ProcsPerMinute`, `Chance`, `Cooldown`, `Charges`)
VALUES
  (561826, 0, 0, 0, 0, 0, 1048576, 0, 0, 0, 0, 0, 0, 100, 0, 0);

-- The model has to be one this client actually holds. 408534 points at
-- creature\demoncrystal\creature_demoncrystal_03_blue.m2, which no archive in the client carries,
-- so it drew as the missing-model chequerboard. 9832 is the Ash'ari Crystal, the blue crystal of
-- the Scourge ziggurats: Creature\ZigguratCrystal\ZigguratCrystal.mdx, spawned in the world
-- already and therefore known to render.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 9832 WHERE `CreatureID` = 557911;

-- The Ash'ari Crystal is a ziggurat-sized prop; at full scale the lure stood taller than the
-- player. A third of it reads as something placed on the ground.
UPDATE `creature_template_model` SET `DisplayScale` = 0.33 WHERE `CreatureID` = 557911;
