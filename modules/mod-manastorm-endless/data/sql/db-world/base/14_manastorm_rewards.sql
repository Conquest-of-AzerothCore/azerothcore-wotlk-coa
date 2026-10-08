-- Shared Manastorm reward policy and Treasure Keeper.
--
-- PROVEN / STRONGLY SUPPORTED:
--   * 1297307 Bedlam Bullion is first-completion progression currency.
--   * 1297308 Bonzo Bolt is repeatable progression currency.
--   * deeper Manastorms increase rewards.
--   * group and map/segment reward multipliers exist.
--   * the native queue hardcodes seven Potential Reward item identities.
--   * Treasure Keeper can spawn from Manastorm trash; its chance rises with
--     kills/depth and it grants bonus chest/cache-style rewards and Cases.
--   * shutdown creaturecache.wdb contains:
--       10111377 Treasure Keeper
--       display 48611
--       rank 1, type 7, type_flags 0, family 0
--       HealthModifier 1.0, ManaModifier 1.0, movementId 999
--
-- RECONSTRUCTED / SERVER TUNING:
--   * Bedlam: 1 + floor((depth-1)/100)
--   * Bonzo: 5 + 2*floor((depth-1)/10)
--   * group reward defaults: 1.0 / 1.1 / 1.2 / 1.3 / 1.4
--   * Treasure Keeper:
--       0.50% base
--       +0.01% per depth
--       +0.10% per eligible trash kill
--       cap 10%
--       one Keeper maximum per stage
--       two bonus caches + one random Ability/Talent Case
--
-- Tuning lives in SQL intentionally so later evidence can replace these
-- reconstructed values without changing the shared gameplay engine.

CREATE TABLE IF NOT EXISTS manastorm_reward_rule
(
    reward_key               VARCHAR(32) NOT NULL,
    item_entry               INT UNSIGNED NOT NULL,
    base_amount              INT UNSIGNED NOT NULL DEFAULT 0,
    depth_step               INT UNSIGNED NOT NULL DEFAULT 1,
    amount_per_step          INT UNSIGNED NOT NULL DEFAULT 0,
    first_clear_only         TINYINT UNSIGNED NOT NULL DEFAULT 0,
    apply_group_multiplier   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    apply_segment_multiplier TINYINT UNSIGNED NOT NULL DEFAULT 1,
    enabled                  TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (reward_key)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO manastorm_reward_rule
(
    reward_key,
    item_entry,
    base_amount,
    depth_step,
    amount_per_step,
    first_clear_only,
    apply_group_multiplier,
    apply_segment_multiplier,
    enabled
)
VALUES
    ('BEDLAM', 1297307, 1, 100, 1, 1, 1, 1, 1),
    ('BONZO',  1297308, 5,  10, 2, 0, 1, 1, 1);

CREATE TABLE IF NOT EXISTS manastorm_reward_group_multiplier
(
    min_members TINYINT UNSIGNED NOT NULL,
    max_members TINYINT UNSIGNED NOT NULL,
    multiplier  DECIMAL(8,4) UNSIGNED NOT NULL DEFAULT 1.0000,
    enabled     TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (min_members, max_members)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO manastorm_reward_group_multiplier
(min_members, max_members, multiplier, enabled)
VALUES
    (1,  1, 1.0000, 1),
    (2,  2, 1.1000, 1),
    (3,  3, 1.2000, 1),
    (4,  4, 1.3000, 1),
    (5, 15, 1.4000, 1);

CREATE TABLE IF NOT EXISTS manastorm_potential_reward
(
    display_order TINYINT UNSIGNED NOT NULL,
    item_entry    INT UNSIGNED NOT NULL,
    enabled       TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (display_order),
    UNIQUE KEY uq_manastorm_potential_reward_item (item_entry)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

-- Exact native ManastormQueue.xml order.
INSERT IGNORE INTO manastorm_potential_reward
(display_order, item_entry, enabled)
VALUES
    (1,  97884,   1), -- Manastorm Cache
    (2,  1297307, 1), -- Bedlam Bullion
    (3,  1297308, 1), -- Bonzo Bolt
    (4,  1278049, 1), -- Case of Fortune: Abilities
    (5,  1278048, 1), -- Case of Fortune: Talents
    (6,  97886,   1), -- Talent Sealed Card Pack
    (7,  97885,   1); -- Ability Sealed Card Pack

CREATE TABLE IF NOT EXISTS manastorm_treasure_keeper_rule
(
    rule_id               TINYINT UNSIGNED NOT NULL,
    creature_entry        INT UNSIGNED NOT NULL,
    base_chance_bp        SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    chance_per_depth_bp   SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    chance_per_kill_bp    SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    max_chance_bp         SMALLINT UNSIGNED NOT NULL DEFAULT 10000,
    bonus_cache_count     INT UNSIGNED NOT NULL DEFAULT 0,
    ability_case_item     INT UNSIGNED NOT NULL DEFAULT 0,
    talent_case_item      INT UNSIGNED NOT NULL DEFAULT 0,
    case_count            INT UNSIGNED NOT NULL DEFAULT 0,
    enabled               TINYINT UNSIGNED NOT NULL DEFAULT 1,

    PRIMARY KEY (rule_id)
)
ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO manastorm_treasure_keeper_rule
(
    rule_id,
    creature_entry,
    base_chance_bp,
    chance_per_depth_bp,
    chance_per_kill_bp,
    max_chance_bp,
    bonus_cache_count,
    ability_case_item,
    talent_case_item,
    case_count,
    enabled
)
VALUES
    (1, 10111377, 50, 1, 10, 1000, 2, 1278049, 1278048, 1, 1);

-- Recovered Treasure Keeper client identity.
--
-- INSERT IGNORE deliberately preserves a more complete original server row
-- if one is already present.
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
    10111377,
    'Treasure Keeper',
    NULL,
    1,
    1,
    0,
    35,
    0,
    1,
    1.14286,
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
    12,
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
    0,
    '',
    NULL
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
    (10111377, 0, 48611, 1, 1, 0);

-- Verification
SELECT * FROM manastorm_reward_rule ORDER BY reward_key;
SELECT * FROM manastorm_reward_group_multiplier ORDER BY min_members;
SELECT * FROM manastorm_potential_reward ORDER BY display_order;
SELECT * FROM manastorm_treasure_keeper_rule WHERE rule_id = 1;

SELECT
    ct.`entry`,
    ct.`name`,
    ct.`rank`,
    ct.`type`,
    ct.`type_flags`,
    ct.`family`,
    ct.`HealthModifier`,
    ct.`ManaModifier`,
    ct.`movementId`,
    ctm.`CreatureDisplayID`
FROM `creature_template` ct
LEFT JOIN `creature_template_model` ctm
    ON ctm.`CreatureID` = ct.`entry`
    AND ctm.`Idx` = 0
WHERE ct.`entry` = 10111377;
