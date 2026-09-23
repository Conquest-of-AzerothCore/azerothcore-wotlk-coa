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
--   * Millhouse/Cogsworth use level 80 server templates.
--   * Cogsley preserves the existing level-1 non-combat-companion semantics
--     (type 12) while restoring its recovered name/subname/model/services.
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
-- No Begin/Continue/Leave stage-controller NPC is authored. Stage flow is
-- owned by the Manastorm runtime; native click-to-next-stage portal work is
-- intentionally deferred until that portal is reconstructed separately.

-- ---------------------------------------------------------------------------
-- Remove obsolete local stage-controller placeholder
-- ---------------------------------------------------------------------------
--
-- Older revisions of this reconstruction created 900027 as a temporary
-- Begin/Continue/Leave NPC. The working Manastorm runtime does not need it.
-- Keep this cleanup so re-running the migration removes the obsolete template
-- from databases that already applied an earlier revision.
--
DELETE FROM `npc_vendor`
WHERE `entry` = 900027;

DELETE FROM `creature_template_model`
WHERE `CreatureID` = 900027;

DELETE FROM `creature_template`
WHERE `entry` = 900027;

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
    1,
    1,
    0,
    35,
    67113089,
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
    3.125,
    1.0,
    1,
    1,
    0,
    0,
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
    `gossip_menu_id` = VALUES(`gossip_menu_id`),
    `minlevel` = VALUES(`minlevel`),
    `maxlevel` = VALUES(`maxlevel`),
    `exp` = VALUES(`exp`),
    `faction` = VALUES(`faction`),
    `npcflag` = VALUES(`npcflag`),
    `speed_walk` = VALUES(`speed_walk`),
    `speed_run` = VALUES(`speed_run`),
    `speed_swim` = VALUES(`speed_swim`),
    `speed_flight` = VALUES(`speed_flight`),
    `detection_range` = VALUES(`detection_range`),
    `rank` = VALUES(`rank`),
    `dmgschool` = VALUES(`dmgschool`),
    `DamageModifier` = VALUES(`DamageModifier`),
    `BaseAttackTime` = VALUES(`BaseAttackTime`),
    `RangeAttackTime` = VALUES(`RangeAttackTime`),
    `BaseVariance` = VALUES(`BaseVariance`),
    `RangeVariance` = VALUES(`RangeVariance`),
    `unit_class` = VALUES(`unit_class`),
    `unit_flags` = VALUES(`unit_flags`),
    `unit_flags2` = VALUES(`unit_flags2`),
    `dynamicflags` = VALUES(`dynamicflags`),
    `family` = VALUES(`family`),
    `type` = VALUES(`type`),
    `type_flags` = VALUES(`type_flags`),
    `AIName` = VALUES(`AIName`),
    `MovementType` = VALUES(`MovementType`),
    `HoverHeight` = VALUES(`HoverHeight`),
    `HealthModifier` = VALUES(`HealthModifier`),
    `ManaModifier` = VALUES(`ManaModifier`),
    `ArmorModifier` = VALUES(`ArmorModifier`),
    `ExperienceModifier` = VALUES(`ExperienceModifier`),
    `RacialLeader` = VALUES(`RacialLeader`),
    `movementId` = VALUES(`movementId`),
    `RegenHealth` = VALUES(`RegenHealth`),
    `CreatureImmunitiesId` = VALUES(`CreatureImmunitiesId`),
    `flags_extra` = VALUES(`flags_extra`),
    `ScriptName` = VALUES(`ScriptName`);

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
-- Recovered Manastorm / portal-platform objects
-- ---------------------------------------------------------------------------
--
-- 105189 / display 300510 is the recovered object named "Manastorm", but the
-- shutdown client cache confirms that its display is the sign/house-style
-- object seen during earlier testing. Keep the template for archaeology, but
-- do NOT use it as the portal platform.
--
-- 20832 / display 1055964 is the shutdown-cache object literally named
-- "Teleport Pad". Its exact cached GAMEOBJECT_TYPE_GENERIC payload is:
--   size 0.7
--   Data0=57, Data3=1, Data10=1, Data12=1, Data15=1
--   all other Data fields = 0
-- This is the portal-platform object to use for the Manastorm hub/portal-pad
-- presentation.
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
    1, 1, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0,
    '',
    '',
    0
),
(
    20832,
    5,
    1055964,
    'Teleport Pad',
    '',
    '',
    '',
    0.7,
    57, 0, 0, 1, 0, 0, 0, 0,
    0, 0, 1, 0, 1, 0, 0, 1,
    0, 0, 0, 0, 0, 0, 0, 0,
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
    -- Current/recovered Millhouse reward catalog.
    (179538,  0,   53834, 0, 0, 4217, 0), -- Empty Heart Container, 200 Bedlam

    -- Archival db.exil Millhouse cosmetic set.
    -- ItemExtendedCost 4220 = 225 Bedlam. This is a reconstruction choice:
    -- the archive proves vendor membership but does not expose the custom
    -- currency amount; 4220 is the otherwise-unassigned low cosmetic tier
    -- present in the recovered shutdown ItemExtendedCost.dbc.
    (179538,  1,   69078, 0, 0, 4220, 0), -- Purple Desert Satin Cord, reconstructed 225 Bedlam
    (179538,  2,   69079, 0, 0, 4220, 0), -- Purple Desert Satin Treads, reconstructed 225 Bedlam
    (179538,  3,   69080, 0, 0, 4220, 0), -- Purple Desert Satin Tunic, reconstructed 225 Bedlam
    (179538,  4,   69081, 0, 0, 4220, 0), -- Purple Desert Satin Gloves, reconstructed 225 Bedlam
    (179538,  5,   69082, 0, 0, 4220, 0), -- Purple Desert Satin Hood, reconstructed 225 Bedlam
    (179538,  6,   69083, 0, 0, 4220, 0), -- Purple Desert Satin Leggings, reconstructed 225 Bedlam
    (179538,  7,   69084, 0, 0, 4220, 0), -- Purple Desert Satin Robe, reconstructed 225 Bedlam
    (179538,  8,   69085, 0, 0, 4220, 0), -- Purple Desert Satin Mantle, reconstructed 225 Bedlam
    (179538,  9,   69086, 0, 0, 4220, 0), -- Purple Desert Satin Cuffs, reconstructed 225 Bedlam
    (179538, 10,   98451, 0, 0, 4220, 0), -- Purple Desert Satin Skirt, reconstructed 225 Bedlam

    (179538, 11,  427920, 0, 0, 4217, 0), -- Millhouse's Goggles of Imminent Peril, 200 Bedlam
    (179538, 12,  453836, 0, 0, 4207, 0), -- Millhouse Mixtape, 500 Bedlam
    (179538, 13,  509890, 0, 0, 4207, 0), -- Manastorm's Duplicator, 500 Bedlam (+ native 350g BuyPrice)
    (179538, 14,  980060, 0, 0, 4207, 0), -- Beastmaster's Whistle: Pink Elekk, 500 Bedlam
    (179538, 15,  222739, 0, 0, 4207, 0), -- Tome of Polymorph: Frogduck, 500 Bedlam

    (179538, 16,  280760, 0, 0, 4209, 0), -- S.A.V.I.O.R, reconstructed 1000 Bedlam
    (179538, 17,  233223, 0, 0, 4210, 0), -- Millhouse's Mystical Transportation Device, 1500 Bedlam
    (179538, 18,  350411, 0, 0, 4215, 0), -- Alchemist's Brewing Staff, reconstructed 1500 Bedlam
    (179538, 19,  532570, 0, 0, 4210, 0), -- Pip, 1500 Bedlam
    (179538, 20,  532571, 0, 0, 4210, 0), -- Boomer, 1500 Bedlam
    (179538, 21,  309907, 0, 0, 4211, 0), -- Recalibrator Pylon, 2000 Bedlam
    (179538, 22, 2903513, 0, 0, 4213, 0), -- Mechanical Mystic Altar, 3000 Bedlam

    -- Public Ascension collection documentation confirms both mount costs.
    (179538, 23,  236415, 0, 0, 4216, 0), -- Celestial Glitterplume, 5000 Bedlam
    (179538, 24,  439040, 0, 0, 4216, 0), -- Tinkertrot, 5000 Bedlam
    (179538, 25,  428236, 0, 0, 4500, 0), -- Reins of Silvershine Sentinel, 20000 Bedlam

    -- Current tome rewards.
    (179538, 26, 1500126, 0, 0, 4221, 0), -- Tome of Eye of Kilrogg, 150 Bedlam
    (179538, 27, 1500128, 0, 0, 4221, 0), -- Tome of Mind Soothe, 150 Bedlam
    (179538, 28, 1500134, 0, 0, 4221, 0), -- Tome of Levitate, 150 Bedlam
    (179538, 29, 1500135, 0, 0, 4221, 0), -- Tome of Safe Fall, 150 Bedlam
    (179538, 30, 1500136, 0, 0, 4221, 0), -- Tome of Mind Vision, 150 Bedlam
    (179538, 31, 1500141, 0, 0, 4221, 0), -- Tome of Teleport: Moonglade, 150 Bedlam
    (179538, 32, 1500153, 0, 0, 4221, 0); -- Tome of Call of the Elements, 150 Bedlam

-- Millhouse is intentionally a union of the two recovered vendor revisions:
--   * the supplied current Page 1/2 + Page 2/2 screenshots;
--   * the archival db.exil vendor membership list.
--
-- This preserves every known reward item instead of discarding historical
-- membership merely because Ascension changed the visible catalog over time.
--
-- Price confidence:
--   PROVEN/current screenshot: 150, 200, 500, 1500, 2000, 3000, 5000 tiers.
--   PROVEN/public guide: Tinkertrot=5000, Silvershine Sentinel=20000.
--   RECONSTRUCTED: Purple Desert Satin set=225 each, S.A.V.I.O.R=1000,
--                  Alchemist's Brewing Staff=1500.
-- The reconstructed prices use native Bedlam rows recovered from the supplied
-- shutdown ItemExtendedCost.dbc rather than inventing custom currency rows.

-- ---------------------------------------------------------------------------
-- Cogsworth <Manastorm Gadget Vendor> — reconstructed full 147-item economy
-- Currency item: 1297308 Bonzo Bolt.
--
-- The Rank-1 prices visible in the later vendor screenshots are authoritative:
--   4208 = 10,000 Bonzo
--   4230 = 20,000 Bonzo
--   4231 = 30,000 Bonzo
--   4232 = 40,000 Bonzo
--   4233 = 50,000 Bonzo
--
-- Rank 2-8 assignments below are an intentional reconstruction by pattern.
-- The shutdown-era screenshot proves the low utility tier used 7,500 Bonzo
-- (ExtendedCost 4438), while ItemExtendedCost.dbc contains five contiguous
-- 9-step upgrade ladders:
--
--   utility / 10k current tier: 4393..4401
--   sprint  / 20k current tier: 4402..4410
--   mobility/ 30k current tier: 4411..4419
--   stat    / 40k current tier: 4420..4428
--   power   / 50k current tier: 4429..4437
--
-- The 147 recovered purchasable items contain exactly eight ranks per ranked
-- family, so only the first seven rows of each ladder are used for R2-R8.
-- The final two rows of each 9-step ladder are left unused/reserved rather than
-- fabricating Rank 9/10 item rows.
--
-- Hearty Heal and Freedom Fizz are assigned to the same utility ladder as
-- Cleanse/Purification/Curing/Interrupt Rod/Motion Lotion because the surviving
-- old Cogsworth screenshot shows all seven at the same 7,500-Bonzo Rank-1
-- price. Millhouse Mobility Mixture is assigned to the otherwise-unused middle
-- (30k current) tier as the best-fit reconstruction.
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
    (179539,   0,  339041, 0, 0, 4208, 0), -- Interrupt Rod R1
    (179539,   1,  439057, 0, 0, 4393, 0), -- Interrupt Rod R2
    (179539,   2,  439058, 0, 0, 4394, 0), -- Interrupt Rod R3
    (179539,   3,  439059, 0, 0, 4395, 0), -- Interrupt Rod R4
    (179539,   4,  439060, 0, 0, 4396, 0), -- Interrupt Rod R5
    (179539,   5,  439061, 0, 0, 4397, 0), -- Interrupt Rod R6
    (179539,   6,  439062, 0, 0, 4398, 0), -- Interrupt Rod R7
    (179539,   7,  439063, 0, 0, 4399, 0), -- Interrupt Rod R8
    (179539,   8,   99269, 0, 0, 4208, 0), -- Hearty Heal Upgrade R1
    (179539,   9,   99270, 0, 0, 4393, 0), -- Hearty Heal Upgrade R2
    (179539,  10,   99271, 0, 0, 4394, 0), -- Hearty Heal Upgrade R3
    (179539,  11,   99272, 0, 0, 4395, 0), -- Hearty Heal Upgrade R4
    (179539,  12,   99273, 0, 0, 4396, 0), -- Hearty Heal Upgrade R5
    (179539,  13,   99274, 0, 0, 4397, 0), -- Hearty Heal Upgrade R6
    (179539,  14,   99275, 0, 0, 4398, 0), -- Hearty Heal Upgrade R7
    (179539,  15,   99276, 0, 0, 4399, 0), -- Hearty Heal Upgrade R8
    (179539,  16,  339030, 0, 0, 4208, 0), -- Cleanse R1
    (179539,  17,  439030, 0, 0, 4393, 0), -- Cleanse R2
    (179539,  18,  439031, 0, 0, 4394, 0), -- Cleanse R3
    (179539,  19,  439032, 0, 0, 4395, 0), -- Cleanse R4
    (179539,  20,  439033, 0, 0, 4396, 0), -- Cleanse R5
    (179539,  21,  439034, 0, 0, 4397, 0), -- Cleanse R6
    (179539,  22,  439045, 0, 0, 4398, 0), -- Cleanse R7
    (179539,  23,  439046, 0, 0, 4399, 0), -- Cleanse R8
    (179539,  24,  339031, 0, 0, 4208, 0), -- Purification R1
    (179539,  25,  539031, 0, 0, 4393, 0), -- Purification R2
    (179539,  26,  539032, 0, 0, 4394, 0), -- Purification R3
    (179539,  27,  539033, 0, 0, 4395, 0), -- Purification R4
    (179539,  28,  539034, 0, 0, 4396, 0), -- Purification R5
    (179539,  29,  539035, 0, 0, 4397, 0), -- Purification R6
    (179539,  30,  539036, 0, 0, 4398, 0), -- Purification R7
    (179539,  31,  539037, 0, 0, 4399, 0), -- Purification R8
    (179539,  32,  339033, 0, 0, 4208, 0), -- Curing R1
    (179539,  33,  439035, 0, 0, 4393, 0), -- Curing R2
    (179539,  34,  439036, 0, 0, 4394, 0), -- Curing R3
    (179539,  35,  439133, 0, 0, 4395, 0), -- Curing R4
    (179539,  36,  439134, 0, 0, 4396, 0), -- Curing R5
    (179539,  37,  439135, 0, 0, 4397, 0), -- Curing R6
    (179539,  38,  439136, 0, 0, 4398, 0), -- Curing R7
    (179539,  39,  439137, 0, 0, 4399, 0), -- Curing R8
    (179539,  40,  339074, 0, 0, 4208, 0), -- Motion Lotion R1
    (179539,  41,  439113, 0, 0, 4393, 0), -- Motion Lotion R2
    (179539,  42,  439114, 0, 0, 4394, 0), -- Motion Lotion R3
    (179539,  43,  439115, 0, 0, 4395, 0), -- Motion Lotion R4
    (179539,  44,  439116, 0, 0, 4396, 0), -- Motion Lotion R5
    (179539,  45,  439117, 0, 0, 4397, 0), -- Motion Lotion R6
    (179539,  46,  439131, 0, 0, 4398, 0), -- Motion Lotion R7
    (179539,  47,  439132, 0, 0, 4399, 0), -- Motion Lotion R8
    (179539,  48,   99290, 0, 0, 4208, 0), -- Freedom Fizz R1
    (179539,  49,   99291, 0, 0, 4393, 0), -- Freedom Fizz R2
    (179539,  50,   99292, 0, 0, 4394, 0), -- Freedom Fizz R3
    (179539,  51,   99293, 0, 0, 4395, 0), -- Freedom Fizz R4
    (179539,  52,   99294, 0, 0, 4396, 0), -- Freedom Fizz R5
    (179539,  53,   99295, 0, 0, 4397, 0), -- Freedom Fizz R6
    (179539,  54,   99296, 0, 0, 4398, 0), -- Freedom Fizz R7
    (179539,  55,   99297, 0, 0, 4399, 0), -- Freedom Fizz R8
    (179539,  56,  339050, 0, 0, 4230, 0), -- Sprint Serum R1
    (179539,  57,  439050, 0, 0, 4402, 0), -- Sprint Serum R2
    (179539,  58,  439051, 0, 0, 4403, 0), -- Sprint Serum R3
    (179539,  59,  439052, 0, 0, 4404, 0), -- Sprint Serum R4
    (179539,  60,  439053, 0, 0, 4405, 0), -- Sprint Serum R5
    (179539,  61,  439054, 0, 0, 4406, 0), -- Sprint Serum R6
    (179539,  62,  439055, 0, 0, 4407, 0), -- Sprint Serum R7
    (179539,  63,  439056, 0, 0, 4408, 0), -- Sprint Serum R8
    (179539,  64, 1300179, 0, 0, 4231, 0), -- Millhouse Mobility Mixture R1
    (179539,  65, 1300186, 0, 0, 4411, 0), -- Millhouse Mobility Mixture R2
    (179539,  66, 1300187, 0, 0, 4412, 0), -- Millhouse Mobility Mixture R3
    (179539,  67, 1300188, 0, 0, 4413, 0), -- Millhouse Mobility Mixture R4
    (179539,  68, 1300189, 0, 0, 4414, 0), -- Millhouse Mobility Mixture R5
    (179539,  69, 1300190, 0, 0, 4415, 0), -- Millhouse Mobility Mixture R6
    (179539,  70, 1300191, 0, 0, 4416, 0), -- Millhouse Mobility Mixture R7
    (179539,  71, 1300192, 0, 0, 4417, 0), -- Millhouse Mobility Mixture R8
    (179539,  72,  339077, 0, 0, 4232, 0), -- Taunting Tonic R1
    (179539,  73,  439125, 0, 0, 4420, 0), -- Taunting Tonic R2
    (179539,  74,  439126, 0, 0, 4421, 0), -- Taunting Tonic R3
    (179539,  75,  439127, 0, 0, 4422, 0), -- Taunting Tonic R4
    (179539,  76,  439128, 0, 0, 4423, 0), -- Taunting Tonic R5
    (179539,  77,  439129, 0, 0, 4424, 0), -- Taunting Tonic R6
    (179539,  78,  439130, 0, 0, 4425, 0), -- Taunting Tonic R7
    (179539,  79,  439138, 0, 0, 4426, 0), -- Taunting Tonic R8
    (179539,  80,  339034, 0, 0, 4232, 0), -- Muscle Maxer R1
    (179539,  81,  439037, 0, 0, 4420, 0), -- Muscle Maxer R2
    (179539,  82,  439038, 0, 0, 4421, 0), -- Muscle Maxer R3
    (179539,  83,  439039, 0, 0, 4422, 0), -- Muscle Maxer R4
    (179539,  84,  439041, 0, 0, 4423, 0), -- Muscle Maxer R5
    (179539,  85,  439042, 0, 0, 4424, 0), -- Muscle Maxer R6
    (179539,  86,  439043, 0, 0, 4425, 0), -- Muscle Maxer R7
    (179539,  87,  439044, 0, 0, 4426, 0), -- Muscle Maxer R8
    (179539,  88,  339035, 0, 0, 4232, 0), -- Genius Juice R1
    (179539,  89,  439064, 0, 0, 4420, 0), -- Genius Juice R2
    (179539,  90,  439065, 0, 0, 4421, 0), -- Genius Juice R3
    (179539,  91,  439066, 0, 0, 4422, 0), -- Genius Juice R4
    (179539,  92,  439067, 0, 0, 4423, 0), -- Genius Juice R5
    (179539,  93,  439068, 0, 0, 4424, 0), -- Genius Juice R6
    (179539,  94,  439069, 0, 0, 4425, 0), -- Genius Juice R7
    (179539,  95,  439070, 0, 0, 4426, 0), -- Genius Juice R8
    (179539,  96,  339037, 0, 0, 4232, 0), -- Reflex Booster R1
    (179539,  97,  439078, 0, 0, 4420, 0), -- Reflex Booster R2
    (179539,  98,  439079, 0, 0, 4421, 0), -- Reflex Booster R3
    (179539,  99,  439080, 0, 0, 4422, 0), -- Reflex Booster R4
    (179539, 100,  439081, 0, 0, 4423, 0), -- Reflex Booster R5
    (179539, 101,  439082, 0, 0, 4424, 0), -- Reflex Booster R6
    (179539, 102,  439083, 0, 0, 4425, 0), -- Reflex Booster R7
    (179539, 103,  439084, 0, 0, 4426, 0), -- Reflex Booster R8
    (179539, 104,  339036, 0, 0, 4232, 0), -- Chakra Chug R1
    (179539, 105,  439071, 0, 0, 4420, 0), -- Chakra Chug R2
    (179539, 106,  439072, 0, 0, 4421, 0), -- Chakra Chug R3
    (179539, 107,  439073, 0, 0, 4422, 0), -- Chakra Chug R4
    (179539, 108,  439074, 0, 0, 4423, 0), -- Chakra Chug R5
    (179539, 109,  439075, 0, 0, 4424, 0), -- Chakra Chug R6
    (179539, 110,  439076, 0, 0, 4425, 0), -- Chakra Chug R7
    (179539, 111,  439077, 0, 0, 4426, 0), -- Chakra Chug R8
    (179539, 112,  339063, 0, 0, 4233, 0), -- Incantation Intensifier R1
    (179539, 113,  439085, 0, 0, 4429, 0), -- Incantation Intensifier R2
    (179539, 114,  439086, 0, 0, 4430, 0), -- Incantation Intensifier R3
    (179539, 115,  439087, 0, 0, 4431, 0), -- Incantation Intensifier R4
    (179539, 116,  439088, 0, 0, 4432, 0), -- Incantation Intensifier R5
    (179539, 117,  439089, 0, 0, 4433, 0), -- Incantation Intensifier R6
    (179539, 118,  439090, 0, 0, 4434, 0), -- Incantation Intensifier R7
    (179539, 119,  439091, 0, 0, 4435, 0), -- Incantation Intensifier R8
    (179539, 120,  339070, 0, 0, 4233, 0), -- Long Haul Liquid R1
    (179539, 121,  439092, 0, 0, 4429, 0), -- Long Haul Liquid R2
    (179539, 122,  439093, 0, 0, 4430, 0), -- Long Haul Liquid R3
    (179539, 123,  439094, 0, 0, 4431, 0), -- Long Haul Liquid R4
    (179539, 124,  439095, 0, 0, 4432, 0), -- Long Haul Liquid R5
    (179539, 125,  439096, 0, 0, 4433, 0), -- Long Haul Liquid R6
    (179539, 126,  439097, 0, 0, 4434, 0), -- Long Haul Liquid R7
    (179539, 127,  439098, 0, 0, 4435, 0), -- Long Haul Liquid R8
    (179539, 128,  339071, 0, 0, 4233, 0), -- Harm Repellant Remedy R1
    (179539, 129,  439099, 0, 0, 4429, 0), -- Harm Repellant Remedy R2
    (179539, 130,  439100, 0, 0, 4430, 0), -- Harm Repellant Remedy R3
    (179539, 131,  439101, 0, 0, 4431, 0), -- Harm Repellant Remedy R4
    (179539, 132,  439102, 0, 0, 4432, 0), -- Harm Repellant Remedy R5
    (179539, 133,  439103, 0, 0, 4433, 0), -- Harm Repellant Remedy R6
    (179539, 134,  439104, 0, 0, 4434, 0), -- Harm Repellant Remedy R7
    (179539, 135,  439105, 0, 0, 4435, 0), -- Harm Repellant Remedy R8
    (179539, 136,  339072, 0, 0, 4233, 0), -- Rage Rush Solution R1
    (179539, 137,  439106, 0, 0, 4429, 0), -- Rage Rush Solution R2
    (179539, 138,  439107, 0, 0, 4430, 0), -- Rage Rush Solution R3
    (179539, 139,  439108, 0, 0, 4431, 0), -- Rage Rush Solution R4
    (179539, 140,  439109, 0, 0, 4432, 0), -- Rage Rush Solution R5
    (179539, 141,  439110, 0, 0, 4433, 0), -- Rage Rush Solution R6
    (179539, 142,  439111, 0, 0, 4434, 0), -- Rage Rush Solution R7
    (179539, 143,  439112, 0, 0, 4435, 0), -- Rage Rush Solution R8
    (179539, 144,  339042, 0, 0, 4208, 0), -- Frogduck Morph Machine, 10,000
    (179539, 145,  439124, 0, 0, 4208, 0), -- Purge-O-Matic, 10,000
    (179539, 146,  339062, 0, 0, 4231, 0); -- Tiny Ticking Time-Bomb, 30,000

-- Unused tail rows of the five 9-step ladders, retained for future evidence:
--   4400, 4401
--   4409, 4410
--   4418, 4419
--   4427, 4428
--   4436, 4437
--
-- Cogsley (80919) is restored as the native in-Manastorm NPC template/model.
-- Its screenshot proves that it can expose a combined Millhouse/Cogsworth
-- catalog, but a complete authoritative Cogsley per-item roster is still not
-- reconstructed here.


-- ---------------------------------------------------------------------------
-- Cogsley <Manastorm Gadget Vendor> — summonable/mobile Cogsworth vendor
-- ---------------------------------------------------------------------------
--
-- External Manastorm guide evidence identifies Cogsley as a companion/pet
-- specifically used to vendor while inside Manastorm. The recovered summon
-- spell is 93418 -> creature 80919.
--
-- Reconstruction choice:
--   Cogsley is the portable/pet counterpart of Cogsworth. Its vendor inventory
--   therefore references Cogsworth 179539 directly instead of duplicating
--   147 rows here. AzerothCore supports vendor references through a negative
--   item value, so future Cogsworth corrections automatically reach Cogsley.
--
-- This also means future corrections to Cogsworth's item/ExtendedCost rows
-- automatically propagate to Cogsley.
--
-- IMPORTANT:
--   80919 is NOT a permanent capital/world spawn. It is a summoned companion
--   template. No creature spawn row should be authored for Cogsley.
-- ---------------------------------------------------------------------------

DELETE FROM `npc_vendor`
WHERE `entry` = 80919;

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
    (80919, 0, -179539, 0, 0, 0, 0); -- Reference Cogsworth's full vendor list

-- Research note:
-- The older 0-50 / 51-100 / ... / 1901+ Manastorm table is a CACHE-LOOT
-- bracket table, not a segment/dungeon-selection wall. It intentionally does
-- not belong in this hub/vendor migration and must not be used to gate segment
-- availability.

-- ---------------------------------------------------------------------------
-- Cogsley companion summon
-- ---------------------------------------------------------------------------
--
-- Item 98074 teaches spell 93418. The recovered item text explicitly says
-- Cogsley is a non-combat companion that only works in the Manastorm.
-- Spell 93418 already performs the native summon of creature 80919; binding it
-- to the shared Manastorm tool validator only adds the missing stage restriction.
--
DELETE FROM `spell_script_names`
WHERE `spell_id` = 93418
  AND `ScriptName` = 'spell_manastorm_baseline_tool';

INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`)
VALUES (93418, 'spell_manastorm_baseline_tool');
