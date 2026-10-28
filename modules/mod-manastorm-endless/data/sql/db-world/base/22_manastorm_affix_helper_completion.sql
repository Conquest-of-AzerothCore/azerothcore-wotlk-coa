-- Manastorm affix helper completion.
--
-- Apply this AFTER 21_manastorm_affix_engine_v6.sql on databases that already
-- received the v6 affix migration.
--
-- Evidence boundary:
--   * Spell.dbc proves the helper summon dependencies:
--       Meteor          -> 663025
--       Shards of Magic -> 663026
--       Vortex          -> 663029
--   * Preserved Exiles/client data proves 663029 Vortex is a neutral
--     "Visual Indicator" with display 11686.
--   * Preserved Exiles/client data proves 80916 Creeping Frost is a hostile
--     boss-style helper with display 14501, type=10, type_flags=4.
--   * Raw Ascension Creature.dbc preserves entry/name/display linkage for
--     663025 and 663026: both use display 11686.
--
-- Original server-only faction/AI/flag/stat rows for 663025/663026 were not
-- recovered. The rows below therefore use the same inert, non-selectable
-- compatibility treatment used by the module's other visual helpers.
--
-- INSERT IGNORE is intentional: never overwrite a future/original server row.

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
(663025,'Manastorm Meteor Dummy','',1,1,0,35,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

(663026,'Shards of Magic','',1,1,0,35,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

(663029,'Vortex','Visual Indicator',1,1,0,7,1,1.14286,1,1,0,0,0,1,2000,2000,1,1,1,
 33554434,10,0,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL),

(80916,'Creeping Frost','',1,1,0,14,1,1.14286,1,1,0,3,0,1,2000,2000,1,1,1,
 33554434,10,4,0,'NullCreatureAI',0,1,1.0,1.0,1,1,0,0,64,'',NULL);

INSERT IGNORE INTO `creature_template_model`
(`CreatureID`,`Idx`,`CreatureDisplayID`,`DisplayScale`,`Probability`,`VerifiedBuild`)
VALUES
(663025,0,11686,1,1,NULL),
(663026,0,11686,1,1,NULL),
(663029,0,11686,1,1,NULL),
(80916,0,14501,1,1,NULL);

UPDATE `manastorm_affix_catalog`
SET `helper_creature_entry_1` = 663029
WHERE `affix_id` = 26;

UPDATE `manastorm_affix_catalog`
SET `helper_creature_entry_1` = 663025
WHERE `affix_id` = 93316;

UPDATE `manastorm_affix_catalog`
SET `helper_creature_entry_1` = 80916
WHERE `affix_id` = 93341;

UPDATE `manastorm_affix_catalog`
SET `helper_creature_entry_1` = 663026
WHERE `affix_id` = 93403;
