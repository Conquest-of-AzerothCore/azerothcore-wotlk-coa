-- Manastorm Greedy Demon treasure encounter.
--
-- PROVEN / STRONGLY SUPPORTED:
--   * 75121 is Greedy Demon <Classic>; display 48504.
--   * Greedy Demon is a Manastorm treasure-mob archetype and must not inherit
--     ordinary Manastorm affixes.
--   * its recovered spell family includes:
--       875121 Shadow Shift
--       875123 Fel Protection (-80% damage taken, 10 sec)
--       875126 Shadow Escape
--       875128 Fel Shock
--       875130 Fel Confusion
--       875131 Shadow Escape immunity
--   * recovered loot-explosion spells create sword-shaped loot objects:
--       760301 -> 710014 Uncommon
--       760302 -> 710015 Rare
--       760303 -> 710016 Epic
--   * all three loot objects use client display 4175.
--   * Ascension increased Greedy treasure-mob weighting with Manastorm depth.
--
-- RECONSTRUCTED / SERVER TUNING:
--   * exact native spawn percentage was not recovered.
--   * exact native AI scheduler was not recovered.
--   * exact historical Manastorm sword-loot pool was not recovered.
--   * defaults below therefore remain SQL-driven and replaceable without
--     rewriting the encounter runtime.
--
-- Default reconstruction:
--   * 1.00% stage chance at depth 1
--   * +0.05% per additional depth
--   * cap 10.00%
--   * 35 sec chase before escape
--   * quality weights: 70 / 25 / 5
--   * 20-25 gold on a successfully opened sword
--   * gear pool is seeded from existing equippable uncommon/rare/epic items
--     and can be curated later by editing manastorm_greedy_demon_loot_pool.

CREATE TABLE IF NOT EXISTS `manastorm_greedy_demon_rule`
(
    `rule_id`                TINYINT UNSIGNED NOT NULL,
    `creature_entry`         INT UNSIGNED NOT NULL,
    `min_depth`              INT UNSIGNED NOT NULL DEFAULT 1,
    `base_chance_bp`         SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `chance_per_depth_bp`    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `max_chance_bp`          SMALLINT UNSIGNED NOT NULL DEFAULT 10000,
    `escape_delay_ms`        INT UNSIGNED NOT NULL DEFAULT 35000,
    `shift_interval_ms`      INT UNSIGNED NOT NULL DEFAULT 8000,
    `shock_interval_ms`      INT UNSIGNED NOT NULL DEFAULT 7000,
    `confusion_interval_ms`  INT UNSIGNED NOT NULL DEFAULT 12000,
    `gold_min_copper`        INT UNSIGNED NOT NULL DEFAULT 0,
    `gold_max_copper`        INT UNSIGNED NOT NULL DEFAULT 0,
    `uncommon_weight`        INT UNSIGNED NOT NULL DEFAULT 95,
    `rare_weight`            INT UNSIGNED NOT NULL DEFAULT 4,
    `epic_weight`            INT UNSIGNED NOT NULL DEFAULT 1,
    `enabled`                TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (`rule_id`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO `manastorm_greedy_demon_rule`
(
    `rule_id`,
    `creature_entry`,
    `min_depth`,
    `base_chance_bp`,
    `chance_per_depth_bp`,
    `max_chance_bp`,
    `escape_delay_ms`,
    `shift_interval_ms`,
    `shock_interval_ms`,
    `confusion_interval_ms`,
    `gold_min_copper`,
    `gold_max_copper`,
    `uncommon_weight`,
    `rare_weight`,
    `epic_weight`,
    `enabled`
)
VALUES
(
    1,
    75121,
    1,
    100,
    5,
    1000,
    35000,
    8000,
    7000,
    12000,
    200000,
    250000,
    95,
    4,
    1,
    1
);

-- Classic+ reconstruction: keep higher-quality Greedy Demon swords uncommon.
-- Exact shutdown-era Ascension percentages have not been recovered.
-- UPDATE is intentional so existing installs that already ran this base file
-- receive the corrected Classic+ tier weighting as well.
UPDATE `manastorm_greedy_demon_rule`
SET
    `uncommon_weight` = 95,
    `rare_weight` = 4,
    `epic_weight` = 1
WHERE `rule_id` = 1;

CREATE TABLE IF NOT EXISTS `manastorm_greedy_demon_loot_pool`
(
    `item_entry`        INT UNSIGNED NOT NULL,
    `quality_tier`      TINYINT UNSIGNED NOT NULL,
    `min_player_level`  TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `max_player_level`  TINYINT UNSIGNED NOT NULL DEFAULT 80,
    `weight`            INT UNSIGNED NOT NULL DEFAULT 1,
    `enabled`           TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (`item_entry`),
    KEY `idx_manastorm_greedy_quality_level`
        (`quality_tier`, `min_player_level`, `max_player_level`, `enabled`)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

-- Reconstruction seed only.
-- Keep this pool inspectable/editable instead of hard-coding item identities
-- into C++. Quest-only items, non-equipment and zero-value placeholders are
-- deliberately excluded.
INSERT IGNORE INTO `manastorm_greedy_demon_loot_pool`
(
    `item_entry`,
    `quality_tier`,
    `min_player_level`,
    `max_player_level`,
    `weight`,
    `enabled`
)
SELECT
    it.`entry`,
    it.`Quality`,
    GREATEST(1, it.`RequiredLevel`),
    LEAST(
        80,
        GREATEST(
            15,
            it.`RequiredLevel` + 15)),
    1,
    1
FROM `item_template` it
WHERE it.`class` IN (2, 4)
  AND it.`Quality` IN (2, 3, 4)
  AND it.`InventoryType` NOT IN (0, 4, 19)
  AND it.`RequiredLevel` BETWEEN 1 AND 60
  AND it.`bonding` <> 4
  AND it.`SellPrice` > 0;

-- Recovered Classic Greedy Demon client identity.
-- INSERT IGNORE preserves any more complete server row already present.
INSERT IGNORE INTO `creature_template`
(
    `entry`,
    `name`,
    `subname`,
    `minlevel`,
    `maxlevel`,
    `exp`,
    `faction`,
    `npcflag`,
    `speed_walk`,
    `speed_run`,
    `speed_swim`,
    `speed_flight`,
    `detection_range`,
    `rank`,
    `dmgschool`,
    `DamageModifier`,
    `BaseAttackTime`,
    `RangeAttackTime`,
    `BaseVariance`,
    `RangeVariance`,
    `unit_class`,
    `unit_flags`,
    `unit_flags2`,
    `dynamicflags`,
    `family`,
    `type`,
    `type_flags`,
    `AIName`,
    `MovementType`,
    `HoverHeight`,
    `HealthModifier`,
    `ManaModifier`,
    `ArmorModifier`,
    `ExperienceModifier`,
    `RacialLeader`,
    `movementId`,
    `RegenHealth`,
    `CreatureImmunitiesId`,
    `flags_extra`,
    `ScriptName`,
    `VerifiedBuild`
)
VALUES
(
    75121,
    'Greedy Demon',
    'Classic',
    1,
    1,
    0,
    14,
    0,
    1,
    1.5,
    1,
    1,
    20,
    0,
    0,
    1,
    2000,
    2000,
    1,
    1,
    1,
    0,
    0,
    0,
    0,
    3,
    0,
    '',
    0,
    1,
    1.0,
    1.0,
    1,
    1,
    0,
    0,
    1,
    0,
    64,
    'npc_manastorm_greedy_demon',
    0
);

INSERT IGNORE INTO `creature_template_model`
(
    `CreatureID`,
    `Idx`,
    `CreatureDisplayID`,
    `DisplayScale`,
    `Probability`,
    `VerifiedBuild`
)
VALUES
    (75121, 0, 48504, 1, 1, 0);

-- Existing recovered rows still need this module's encounter AI.
UPDATE `creature_template`
SET
    `AIName` = '',
    `ScriptName` = 'npc_manastorm_greedy_demon'
WHERE `entry` = 75121;

-- Recovered Greedy Demon loot swords.
-- Type 3 = chest. The GameObjectScript intercepts opening and generates the
-- level-aware reconstructed reward; ordinary static gameobject loot is not
-- used for these Manastorm-only summoned objects.
INSERT IGNORE INTO `gameobject_template`
(
    `entry`, `type`, `displayId`, `name`,
    `IconName`, `castBarCaption`, `unk1`, `size`,
    `Data0`, `Data1`, `Data2`, `Data3`,
    `Data4`, `Data5`, `Data6`, `Data7`,
    `Data8`, `Data9`, `Data10`, `Data11`,
    `Data12`, `Data13`, `Data14`, `Data15`,
    `Data16`, `Data17`, `Data18`, `Data19`,
    `Data20`, `Data21`, `Data22`, `Data23`,
    `AIName`, `ScriptName`, `VerifiedBuild`
)
VALUES
(710014,3,4175,'Loot','','','','1',
 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
 '','go_manastorm_greedy_loot',0),
(710015,3,4175,'Loot','','','','1',
 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
 '','go_manastorm_greedy_loot',0),
(710016,3,4175,'Loot','','','','1',
 0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
 '','go_manastorm_greedy_loot',0);

UPDATE `gameobject_template`
SET `ScriptName` = 'go_manastorm_greedy_loot'
WHERE `entry` IN (710014, 710015, 710016);

-- Verification
SELECT *
FROM `manastorm_greedy_demon_rule`
WHERE `rule_id` = 1;

SELECT
    `quality_tier`,
    COUNT(*) AS `pool_rows`
FROM `manastorm_greedy_demon_loot_pool`
WHERE `enabled` = 1
GROUP BY `quality_tier`
ORDER BY `quality_tier`;

SELECT
    `entry`,
    `name`,
    `subname`,
    `AIName`,
    `ScriptName`
FROM `creature_template`
WHERE `entry` = 75121;

SELECT
    `entry`,
    `type`,
    `displayId`,
    `name`,
    `ScriptName`
FROM `gameobject_template`
WHERE `entry` IN (710014, 710015, 710016)
ORDER BY `entry`;
