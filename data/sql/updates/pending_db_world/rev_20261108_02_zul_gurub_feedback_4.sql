-- Zul'Gurub, tester feedback round 4 (2026-11-08).
-- Venoxis's Parasitic Serpents: 979 health per player (live 10,768 at 11 players, 2026-08-02), on the ZG ladder.
-- Spawn of Mar'li: 3,304 health per player (live 36,342 at 11 players, 2026-08-02), on the ZG ladder.
DELETE FROM `coa_boss_flex` WHERE `entry` IN (14884, 15041);
INSERT INTO `coa_boss_flex` (`entry`, `hp_d0`, `hp_d1`, `hp_d2`, `hp_d3`, `comment`) VALUES
(14884, 979, 1410, 1841, 2271, 'ZG Parasitic Serpent: live 10,768 at 11 players (measured)'),
(15041, 3304, 4758, 6212, 7665, 'ZG Spawn of Mar''li: live 36,342 at 11 players (measured)');

-- Hakkar can be taunted, as on live: the same immunities without the taunt effect and aura.
UPDATE `creature_template` SET `CreatureImmunitiesId` = -273 WHERE `entry` IN (14834, 114834, 214834, 314834);

-- The two Sons of Hakkar patrolling the sides respawn like the other Sons.
UPDATE `creature` SET `spawntimesecs` = 7200 WHERE `guid` IN (49033, 49034) AND `id` = 11357;

-- Opening a Jinxed Hoodoo Pile no longer mind-controls the player with Will of Hakkar.
UPDATE `gameobject_template` SET `Data3` = 0 WHERE `entry` = 180244;

-- Gri'lek's melee calibrated to the live median hit (17,520 with his avatar), on the ZG ladder.
UPDATE `creature_template` SET `DamageModifier` = 85.7 WHERE `entry` = 15082;
UPDATE `creature_template` SET `DamageModifier` = 123.4 WHERE `entry` = 115082;
UPDATE `creature_template` SET `DamageModifier` = 161.1 WHERE `entry` = 215082;
UPDATE `creature_template` SET `DamageModifier` = 198.8 WHERE `entry` = 315082;

-- Mandokir rides Ohgan on his own double-size display before the fight.
UPDATE `creature_template_addon` SET `mount` = 215271 WHERE `entry` IN (11382, 111382, 211382, 311382);

-- The Shade of Jin'do casts Seeking Shadow Bolts (boss_jindo_coa).
UPDATE `creature_template` SET `ScriptName` = 'npc_shade_of_jindo_coa' WHERE `entry` = 14986;
