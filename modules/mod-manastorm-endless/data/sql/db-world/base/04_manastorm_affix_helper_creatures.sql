-- Recovered Manastorm affix helper creatures.
-- Evidence:
--   * AscensionDB preserved Exiles NPC pages (name/display/Hostile-or-Neutral/Boss presentation)
--   * client Creature.dbc rows (entry/name/display linkage)
--   * client creature-cache captures (rank/type/type_flags/family/models/HealthModifier/ManaModifier/movementId)
--   * 2026-09-13 preserved Exiles creature export (Vortex/Creeping Frost identity metadata)
--
-- IMPORTANT EVIDENCE BOUNDARY:
-- The original numeric server faction, unit_flags, flags_extra, AIName, level range,
-- damage/armor values and server MovementType were not recovered from those records.
--
-- Server-safe implementation choices below:
--   Hostile page-side -> faction 14 (Monster, hostile to players)
--   Neutral page-side -> faction 7 (Creature, neutral masks)
--   unit_flags 33554434 = non-attackable + not-selectable helper
--   AIName NullCreatureAI prevents accidental melee/default combat while the recovered
--     affix spell/controller behavior is reconstructed.
--   flags_extra 64 prevents helper XP.
--   MovementType remains 0. Client movementId 998/999 is preserved in comments only;
--     it is NOT the AzerothCore MovementType enum.
--
-- INSERT IGNORE is deliberate: if a future source supplies an original full server
-- creature_template row, this reconstruction must not overwrite it.

INSERT IGNORE INTO `creature_template`
(
    `entry`, `name`, `subname`,
    `minlevel`, `maxlevel`, `exp`, `faction`,
    `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`,
    `detection_range`, `rank`, `dmgschool`, `DamageModifier`,
    `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`,
    `unit_class`, `unit_flags`, `type`, `type_flags`, `family`,
    `AIName`, `MovementType`, `HoverHeight`,
    `HealthModifier`, `ManaModifier`, `ArmorModifier`,
    `ExperienceModifier`, `RegenHealth`, `CreatureImmunitiesId`,
    `flags_extra`, `ScriptName`, `VerifiedBuild`
)
VALUES
-- 663025 Manastorm Meteor Dummy
-- Recovered client Creature.dbc: exact entry/name/display=11686.
-- Original numeric server faction/flags/AI were not preserved.  This is an
-- inert visual helper, so use the same safe world-trigger treatment as other
-- Manastorm visual indicators.
(663025,'Manastorm Meteor Dummy','',1,1,0,35,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

-- 663026 Shards of Magic
-- Recovered client Creature.dbc: exact entry/name/display=11686.
-- The helper is summoned by Shards of Magic Precast; original server-only
-- combat fields were not preserved.
(663026,'Shards of Magic','',1,1,0,35,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

-- 663029 Vortex
-- Preserved Exiles: Neutral, subname Visual Indicator, display=11686.
-- Spell.dbc proves 93382 summons this exact entry with SummonProperties 64.
(663029,'Vortex','Visual Indicator',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

-- 80913 Bonestorm
-- Recovered: Hostile, Boss/rank=3, type_flags=4, type=10, family=0,
-- display 14501, HP mod 0.7, mana mod 1.0, client movementId=999.
(80913,'Bonestorm','',1,1,0,14,1,1.14286,1,1,0,3,0,1,2000,2000,1,1,1,
 33554434,10,4,0,'NullCreatureAI',0,1,0.7,1.0,1,1,0,0,64,'',NULL),

-- 80914 Mushroom (Fungal helper)
-- Recovered: Hostile, Boss/rank=3, type_flags=4, type=10, family=0,
-- display 14501, HP mod 0.7, mana mod 1.0, client movementId=999.
(80914,'Mushroom','',1,1,0,14,1,1.14286,1,1,0,3,0,1,2000,2000,1,1,1,
 33554434,10,4,0,'NullCreatureAI',0,1,0.7,1.0,1,1,0,0,64,'',NULL),

-- 80916 Creeping Frost
-- Preserved Exiles/client evidence: Hostile, Boss/rank=3, type_flags=4,
-- type=10, family=0, display=14501.  Original numeric server faction/AI
-- were not preserved; use the same inert hostile-helper treatment as the
-- neighboring recovered Manastorm hazard helpers.
(80916,'Creeping Frost','',1,1,0,14,1,1.14286,1,1,0,3,0,1,2000,2000,1,1,1,
 33554434,10,4,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

-- 80917 Overwhelming Energy
-- Recovered: subname Cosmetic, Hostile, Boss/rank=3, type_flags=4, type=10,
-- family=0, display 14501, HP mod 0.7, mana mod 1.0, client movementId=999.
(80917,'Overwhelming Energy','Cosmetic',1,1,0,14,1,1.14286,1,1,0,3,0,1,2000,2000,1,1,1,
 33554434,10,4,0,'NullCreatureAI',0,1,0.7,1.0,1,1,0,0,64,'',NULL),

-- 80922 Wild Magics
-- Recovered: Neutral, rank=0, type_flags=0, type=10, family=0,
-- displays 24890/24895/26622/24898, HP mod 0.2, mana mod 1.0,
-- client movementId=998.
(80922,'Wild Magics','',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,0.2,1.0,1,1,0,0,64,'',NULL),

-- 80923 Wild Magics Cosmetic Dummy
-- Recovered: Neutral, rank=0, type_flags=0, type=10, family=0,
-- display 200003, HP mod 0.2, mana mod 1.0, client movementId=998.
(80923,'Wild Magics Cosmetic Dummy','',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,0.2,1.0,1,1,0,0,64,'',NULL),

-- 80924 Cold Snap
-- Recovered: Neutral, rank=0, type_flags=0, type=10, family=0,
-- display 100003, HP mod 0.2, mana mod 1.0, client movementId=999.
(80924,'Cold Snap','',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,0.2,1.0,1,1,0,0,64,'',NULL),

-- 80925 Cold Snap Effect
-- Recovered: Neutral, rank=0, type_flags=0, type=10, family=0,
-- display 100003, HP mod 0.2, mana mod 1.0, client movementId=999.
(80925,'Cold Snap Effect','',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,0.2,1.0,1,1,0,0,64,'',NULL);

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
(663025,0,11686,1,1,NULL),
(663026,0,11686,1,1,NULL),
(663029,0,11686,1,1,NULL),
(80913,0,14501,1,1,NULL),
(80914,0,14501,1,1,NULL),
(80916,0,14501,1,1,NULL),
(80917,0,14501,1,1,NULL),
(80922,0,24890,1,1,NULL),
(80922,1,24895,1,1,NULL),
(80922,2,26622,1,1,NULL),
(80922,3,24898,1,1,NULL),
(80923,0,200003,1,1,NULL),
(80924,0,100003,1,1,NULL),
(80925,0,100003,1,1,NULL);
