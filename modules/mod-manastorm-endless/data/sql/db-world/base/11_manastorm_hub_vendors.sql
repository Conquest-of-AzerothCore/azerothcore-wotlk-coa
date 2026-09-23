-- Native Ascension Manastorm hub NPCs, validated vendor rows, and hub object.
--
-- Evidence:
--   shutdown creaturecache.wdb:
--     179538 Millhouse Manastorm <Manastorm Rewards>, display 19942
--     179539 Cogsworth <Manastorm Gadget Vendor>, display 100722
--      80919 Cogsley <Manastorm Gadget Vendor>, display 100722
--   shutdown gameobjectcache.wdb:
--     105189 Manastorm, GAMEOBJECT_TYPE_GENERIC (5), display 300510,
--     size 1.0, data0=1, data1=1
--   shutdown ItemExtendedCost.dbc:
--     1297307 = Bedlam Bullion requirements
--     1297308 = Bonzo Bolt requirements
--   surviving vendor screenshots are used only where an item->price mapping is
--   directly visible. Unresolved ranks/items are intentionally NOT guessed.
--
-- Server-only compatibility choices:
--   * faction 35 keeps the hub vendors neutral/friendly.
--   * level 80 is used for the server template because CMSG creature-query cache
--     data does not contain creature level.
--   * display 100722 model geometry comes from the native P.O.S.T. Master model:
--       BoundingRadius=2.41881, CombatReach=0.
--     AzerothCore normalizes a sub-0.1 combat reach to its default at load.
--   * Gender=2 (none) is used for the mechanical 100722 display.
--
-- Required client/server data:
--   CreatureDisplayInfo 19942 and 100722
--   GameObjectDisplayInfo 300510
--   ItemExtendedCost rows referenced below
--   item_template rows for the vendor items
--
-- No capital spawn coordinates are authored here. We have recovered the
-- templates/object identity, but not an authoritative SW/Org GUID+XYZ+O set.

-- ---------------------------------------------------------------------------
-- Creature model support
-- ---------------------------------------------------------------------------

INSERT INTO `creature_model_info`
(
    `DisplayID`,
    `BoundingRadius`,
    `CombatReach`,
    `Gender`,
    `DisplayID_Other_Gender`,
    `VerifiedBuild`
)
VALUES
    (19942,  0.52785, 2.5875, 0, 0, 0),
    (100722, 2.41881, 0.0000, 2, 0, 0)
ON DUPLICATE KEY UPDATE
    `BoundingRadius` = VALUES(`BoundingRadius`),
    `CombatReach` = VALUES(`CombatReach`),
    `Gender` = VALUES(`Gender`),
    `DisplayID_Other_Gender` = VALUES(`DisplayID_Other_Gender`);

-- ---------------------------------------------------------------------------
-- Native Manastorm NPC templates
-- ---------------------------------------------------------------------------

INSERT INTO `creature_template`
(
    `entry`,
    `name`,
    `subname`,
    `IconName`,
    `gossip_menu_id`,
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
    179538,
    'Millhouse Manastorm',
    'Manastorm Rewards',
    'Buy',
    0,
    80,
    80,
    2,
    35,
    128,
    1,
    1.14286,
    1,
    1,
    20,
    1,
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
    7,
    0,
    '',
    0,
    1,
    3.125,
    1.1,
    1,
    1,
    0,
    999,
    1,
    0,
    0,
    '',
    0
),
(
    179539,
    'Cogsworth',
    'Manastorm Gadget Vendor',
    'Buy',
    0,
    80,
    80,
    2,
    35,
    128,
    1,
    1.14286,
    1,
    1,
    20,
    1,
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
    7,
    0,
    '',
    0,
    1,
    3.125,
    1.0,
    1,
    1,
    0,
    999,
    1,
    0,
    0,
    '',
    0
),
(
    80919,
    'Cogsley',
    'Manastorm Gadget Vendor',
    'Buy',
    0,
    80,
    80,
    2,
    35,
    128,
    1,
    1.14286,
    1,
    1,
    20,
    1,
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
    7,
    0,
    '',
    0,
    1,
    3.125,
    1.0,
    1,
    1,
    0,
    999,
    1,
    0,
    0,
    '',
    0
)
ON DUPLICATE KEY UPDATE
    `name` = VALUES(`name`),
    `subname` = VALUES(`subname`),
    `IconName` = VALUES(`IconName`),
    `faction` = VALUES(`faction`),
    `npcflag` = VALUES(`npcflag`),
    `rank` = VALUES(`rank`),
    `type` = VALUES(`type`),
    `type_flags` = VALUES(`type_flags`),
    `HealthModifier` = VALUES(`HealthModifier`),
    `ManaModifier` = VALUES(`ManaModifier`),
    `RacialLeader` = VALUES(`RacialLeader`),
    `movementId` = VALUES(`movementId`);

DELETE FROM `creature_template_model`
WHERE `CreatureID` IN (179538, 179539, 80919);

INSERT INTO `creature_template_model`
(
    `CreatureID`,
    `Idx`,
    `CreatureDisplayID`,
    `DisplayScale`,
    `Probability`,
    `VerifiedBuild`
)
VALUES
    (179538, 0, 19942,  1, 1, 0),
    (179539, 0, 100722, 1, 1, 0),
    (80919,  0, 100722, 1, 1, 0);

-- ---------------------------------------------------------------------------
-- Native Manastorm hub object
-- ---------------------------------------------------------------------------

INSERT INTO `gameobject_template`
(
    `entry`,
    `type`,
    `displayId`,
    `name`,
    `IconName`,
    `castBarCaption`,
    `unk1`,
    `size`,
    `Data0`,
    `Data1`,
    `Data2`,
    `Data3`,
    `Data4`,
    `Data5`,
    `Data6`,
    `Data7`,
    `Data8`,
    `Data9`,
    `Data10`,
    `Data11`,
    `Data12`,
    `Data13`,
    `Data14`,
    `Data15`,
    `Data16`,
    `Data17`,
    `Data18`,
    `Data19`,
    `Data20`,
    `Data21`,
    `Data22`,
    `Data23`,
    `AIName`,
    `ScriptName`,
    `VerifiedBuild`
)
VALUES
(
    105189,
    5,
    300510,
    'Manastorm',
    '',
    '',
    '',
    1,
    1,
    1,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0,
    '',
    '',
    0
)
ON DUPLICATE KEY UPDATE
    `type` = VALUES(`type`),
    `displayId` = VALUES(`displayId`),
    `name` = VALUES(`name`),
    `IconName` = VALUES(`IconName`),
    `castBarCaption` = VALUES(`castBarCaption`),
    `unk1` = VALUES(`unk1`),
    `size` = VALUES(`size`),
    `Data0` = VALUES(`Data0`),
    `Data1` = VALUES(`Data1`),
    `Data2` = VALUES(`Data2`),
    `Data3` = VALUES(`Data3`),
    `Data4` = VALUES(`Data4`),
    `Data5` = VALUES(`Data5`),
    `Data6` = VALUES(`Data6`),
    `Data7` = VALUES(`Data7`),
    `Data8` = VALUES(`Data8`),
    `Data9` = VALUES(`Data9`),
    `Data10` = VALUES(`Data10`),
    `Data11` = VALUES(`Data11`),
    `Data12` = VALUES(`Data12`),
    `Data13` = VALUES(`Data13`),
    `Data14` = VALUES(`Data14`),
    `Data15` = VALUES(`Data15`),
    `Data16` = VALUES(`Data16`),
    `Data17` = VALUES(`Data17`),
    `Data18` = VALUES(`Data18`),
    `Data19` = VALUES(`Data19`),
    `Data20` = VALUES(`Data20`),
    `Data21` = VALUES(`Data21`),
    `Data22` = VALUES(`Data22`),
    `Data23` = VALUES(`Data23`);

-- ---------------------------------------------------------------------------
-- Millhouse Manastorm <Manastorm Rewards> — directly validated prices
-- Currency item: 1297307 Bedlam Bullion.
--
-- 4217 = 200 Bedlam
-- 4207 = 500 Bedlam
-- 4210 = 1500 Bedlam
-- 4211 = 2000 Bedlam
-- 4213 = 3000 Bedlam
-- 4216 = 5000 Bedlam
-- 4221 = 150 Bedlam
--
-- ItemExtendedCost 4215 is also byte-equivalent to 4210 (1500 Bedlam).
-- 4210 is used as the canonical 1500-cost row here.
-- ---------------------------------------------------------------------------

DELETE FROM `npc_vendor`
WHERE `entry` = 179538;

INSERT INTO `npc_vendor`
(
    `entry`,
    `slot`,
    `item`,
    `maxcount`,
    `incrtime`,
    `ExtendedCost`,
    `VerifiedBuild`
)
VALUES
    (179538,  0,   53834, 0, 0, 4217, 0), -- Empty Heart Container, 200 Bedlam
    (179538,  1,  427920, 0, 0, 4217, 0), -- Millhouse's Goggles of Imminent Peril, 200
    (179538,  2,  453836, 0, 0, 4207, 0), -- Millhouse Mixtape, 500
    (179538,  3,  509890, 0, 0, 4207, 0), -- Manastorm's Duplicator, 500
    (179538,  4,  980060, 0, 0, 4207, 0), -- Beastmaster's Whistle: Pink Elekk, 500
    (179538,  5,  233223, 0, 0, 4210, 0), -- Millhouse's Mystical Transportation Device, 1500
    (179538,  6,  532570, 0, 0, 4210, 0), -- Pip, 1500
    (179538,  7,  532571, 0, 0, 4210, 0), -- Boomer, 1500
    (179538,  8,  309907, 0, 0, 4211, 0), -- Recalibrator Pylon, 2000
    (179538,  9, 2903513, 0, 0, 4213, 0), -- Mechanical Mystic Altar, 3000
    (179538, 10,  236415, 0, 0, 4216, 0), -- Celestial Glitterplume, 5000
    (179538, 11, 1500126, 0, 0, 4221, 0), -- Tome of Eye of Kilrogg, 150
    (179538, 12, 1500128, 0, 0, 4221, 0), -- Tome of Mind Soothe, 150
    (179538, 13, 1500134, 0, 0, 4221, 0), -- Tome of Levitate, 150
    (179538, 14, 1500135, 0, 0, 4221, 0), -- Tome of Safe Fall, 150
    (179538, 15, 1500136, 0, 0, 4221, 0), -- Tome of Mind Vision, 150
    (179538, 16, 1500141, 0, 0, 4221, 0), -- Tome of Teleport: Moonglade, 150
    (179538, 17, 1500153, 0, 0, 4221, 0); -- Tome of Call of the Elements, 150

-- Not inserted yet because the exact item->ExtendedCost link is not proven:
--   Tome of Polymorph: Frogduck (visible at 500 Bedlam, item ID not recovered
--   from the supplied shutdown item cache)
--   Purple Desert Satin set
--   S.A.V.I.O.R
--   Alchemist's Brewing Staff
--   Tinkertrot
--   Reins of Silvershine Sentinel
--
-- Their presence is recovered, but this migration does not invent prices.

-- ---------------------------------------------------------------------------
-- Cogsworth <Manastorm Gadget Vendor> — directly validated current-era base
-- prices. Currency item: 1297308 Bonzo Bolt.
--
-- 4208 = 10,000 Bonzo
-- 4230 = 20,000 Bonzo
-- 4231 = 30,000 Bonzo
-- 4232 = 40,000 Bonzo
-- 4233 = 50,000 Bonzo
--
-- Historical screenshots also show an older 7,500-Bonzo economy
-- (ItemExtendedCost 4438), so only the item/price pairs visible in the later
-- 10k/20k/30k/40k/50k screenshots are authored below.
-- ---------------------------------------------------------------------------

DELETE FROM `npc_vendor`
WHERE `entry` = 179539;

INSERT INTO `npc_vendor`
(
    `entry`,
    `slot`,
    `item`,
    `maxcount`,
    `incrtime`,
    `ExtendedCost`,
    `VerifiedBuild`
)
VALUES
    (179539,  0, 339030, 0, 0, 4208, 0), -- Manastorm Cleanse R1, 10,000
    (179539,  1, 339031, 0, 0, 4208, 0), -- Manastorm Purification R1, 10,000
    (179539,  2, 339033, 0, 0, 4208, 0), -- Manastorm Curing R1, 10,000
    (179539,  3, 339041, 0, 0, 4208, 0), -- Interrupt Rod R1, 10,000
    (179539,  4, 339074, 0, 0, 4208, 0), -- Motion Lotion R1, 10,000
    (179539,  5, 339042, 0, 0, 4208, 0), -- Frogduck Morph Machine, 10,000
    (179539,  6, 439124, 0, 0, 4208, 0), -- Purge-O-Matic, 10,000

    (179539,  7, 339050, 0, 0, 4230, 0), -- Sprint Serum R1, 20,000
    (179539,  8, 339062, 0, 0, 4231, 0), -- Tiny Ticking Time-Bomb, 30,000

    (179539,  9, 339034, 0, 0, 4232, 0), -- Muscle Maxer R1, 40,000
    (179539, 10, 339077, 0, 0, 4232, 0), -- Taunting Tonic R1, 40,000
    (179539, 11, 339035, 0, 0, 4232, 0), -- Genius Juice R1, 40,000
    (179539, 12, 339037, 0, 0, 4232, 0), -- Reflex Booster R1, 40,000
    (179539, 13, 339036, 0, 0, 4232, 0), -- Chakra Chug R1, 40,000

    (179539, 14, 339063, 0, 0, 4233, 0), -- Incantation Intensifier R1, 50,000
    (179539, 15, 339070, 0, 0, 4233, 0), -- Long Haul Liquid R1, 50,000
    (179539, 16, 339071, 0, 0, 4233, 0), -- Harm Repellant Remedy R1, 50,000
    (179539, 17, 339072, 0, 0, 4233, 0); -- Rage Rush Solution R1, 50,000

-- Intentionally unresolved/not inserted yet:
--   Hearty Heal Upgrade
--   Freedom Fizz
--   Millhouse Mobility Mixture
--   all Rank 2+ progression items
--
-- ItemExtendedCost 4393..4437 contains five structured Bonzo ladders, but an
-- authoritative item-family -> ladder assignment has not yet been recovered.
-- Keeping those rows out is deliberate: no guessed economy in the live DB.

-- Cogsley (80919) is restored as the native in-Manastorm NPC template/model.
-- Its screenshot proves that it can expose a combined Millhouse/Cogsworth
-- catalog, but its complete per-item vendor mapping is not authored here until
-- the remaining original assignments are proven.
