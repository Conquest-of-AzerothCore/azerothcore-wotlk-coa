-- Book of Artisans: the profession trainer book and its beginner edition.
--
-- Both creatures are recovered from the preservation archive's own record of the live realm
-- (creature cache, 254 and 184 client submissions, captured 2026-09-10), which carries the
-- fields the world database had lost:
--
--   57500  Book of Artisans            type 8 (critter), type_flags 1048576, rank 1,
--                                      display 48503, HealthModifier 1.0, movementId 999
--   57524  Beginner's Book of Artisans type 10, type_flags 134217728, rank 1,
--                                      display 48503, HealthModifier 1.31781, movementId 999
--
-- Display 48503 is Creature\FlyingBook\FlyingBook_01_Pet_purple.mdx (the client's own
-- CreatureDisplayInfo 48503 -> CreatureModelData 5633). The realm shipped 57500 pointing at
-- display 15901, which is Creature\ReinDeer\ReinDeer.mdx at 0.2 scale, and had no 57524 at all,
-- so there was no usable profession book anywhere in the world.
--
-- Trainers: `trainer` 200001 sits on the full book and 200002 on the beginner's copy, which
-- carries one row per profession: the rank that learns the trade, and
-- nothing above it. A beginner's book teaches the first step; the ladder is the full book's.
--
-- The page and the shop (section 5): both books answer a right click with the original's own
-- two options - "I require training!" and "I would like to browse your goods." - and the
-- shelves behind the second are Edna Mullby's counter, entry 1286, cloned row for row, so the
-- book sells the same items at the same prices she does.
--
-- The list is the professions, and only the professions (section 4b): the rows that learn a trade
-- and raise its ceiling. The realm's 200001 was carrying every recipe the game has - 4739 rows -
-- so a player reading the book was looking at a profession's whole catalogue, including the
-- patterns that in 3.3.5 were the reward for finding them somewhere in the world. The book is the
-- one place a profession is learned; a recipe stays where it is taught, sold, dropped, quested
-- for or discovered.
--
-- Spawns: only the Beginner's Book is a world prop - the tutorial sends players to it, "the
-- Beginner's Book of Artisans outside the inn". The full Book of Artisans is a summonable
-- companion instead (items 134987 and 750750 teach spell 750750, SPELL_EFFECT_SUMMON for
-- creature 57500), so it is removed from the map. The archive keeps one example position per
-- creature and no complete spawn list, so that is what the Beginner's Book is placed at: the
-- Barrens example. The orientation is not recorded either; the book faces Ratchet's innkeeper,
-- the nearest one.
--
-- Every statement is idempotent: the file is applied again whenever it changes.

-- ---------------------------------------------------------------------------
-- 1. Book of Artisans (57500): the captured appearance, and the two flags the
--    realm's other clickable props carry so the book can actually be opened
-- ---------------------------------------------------------------------------
-- 57500 is the realm's own creature and the row this module adjusts; a database that has the
-- model but not the row - a rebuilt world, a fresh schema - would otherwise get two books whose
-- section 2 clone has nothing to copy from. Inserted only when it is missing, so the realm's own
-- fields are never overwritten; everything this module depends on is in the UPDATE below.
INSERT INTO `creature_template`
  (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
  SELECT 57500, 0, 0, 0, 0, 0, 'Book of Artisans', '', '', 57500, 80, 80, 0, 35, 177, 1, 1.14286, 1, 1, 20, 1, 0, 1, 0, 0, 1, 1, 1, 768, 0, 0, 0, 8, 135266304, 0, 0, 0, 0, 0, 0, 0, '', 0, 1, 1, 1, 1, 1, 0, 999, 1, 0, 2, 'npc_book_of_artisans', NULL
  FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM `creature_template` WHERE `entry` = 57500);

UPDATE `creature_template` SET
  `subname`       = '',
  `IconName`      = '',
  `type`          = 8,
  -- captured 1048576 (no name plate) | 134217728 (gossip on right click, as the realm's
  -- other prop NPCs and the captured 57524 carry)
  `type_flags`    = 1048576 | 134217728,
  `family`        = 0,
  `rank`          = 1,
  `HealthModifier` = 1.0,
  `ManaModifier`  = 1.0,
  `RacialLeader`  = 0,
  `movementId`    = 999,
  -- gossip (1) | trainer (16) | class trainer (32) | vendor (128) = 177.
  --
  -- The books answer a right click with a page, not a frame - "I require training!" and "I
  -- would like to browse your goods.", the two options of the original - and each half of that
  -- page needs a flag: the gossip bit is what makes the client ask for the page at all
  -- (CMSG_GOSSIP_HELLO), the trainer bits are what let it draw the trainer window, and the
  -- vendor bit is what the core checks before it will send the shelves.
  --
  -- A list sent to a gossip NPC that the client did not ask for is dropped on the floor: that is
  -- what the Books of Ascension hit (rev_20260918_21_spellbook_trainer.sql), and it is why they
  -- carry 48 and no gossip bit. Both lists these books send are asked for - the page's options
  -- are what make the client request the window or the shelves - so the flag that costs another
  -- trainer its window is the flag that earns these two their page.
  `npcflag`       = 177,
  -- the page a right click opens, and the menu the two options live in (section 5)
  `gossip_menu_id` = 57500,
  -- The world database shipped this row with 0x02000000 (UNIT_FLAG_NOT_SELECTABLE), which no
  -- other prop on the realm carries and which costs the book the only interaction it has: a
  -- non-selectable unit is not clickable, so the right click never reached the script and the
  -- book answered nothing. 768 is what the realm's own restored props use - the Destiny
  -- Weavers carry exactly IMMUNE_TO_PC | IMMUNE_TO_NPC - and it keeps the book a prop that
  -- cannot be attacked instead of a killable critter.
  `unit_flags`    = 768,
  `ScriptName`    = 'npc_book_of_artisans'
WHERE `entry` = 57500;

-- ---------------------------------------------------------------------------
-- 2. Beginner's Book of Artisans (57524): a clone of the full book, then the
--    three fields the capture records differently
-- ---------------------------------------------------------------------------
DELETE FROM `creature_template` WHERE `entry` = 57524;
INSERT INTO `creature_template`
  (`entry`, `difficulty_entry_1`, `difficulty_entry_2`, `difficulty_entry_3`, `KillCredit1`, `KillCredit2`, `name`, `subname`, `IconName`, `gossip_menu_id`, `minlevel`, `maxlevel`, `exp`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `speed_swim`, `speed_flight`, `detection_range`, `rank`, `dmgschool`, `DamageModifier`, `BaseAttackTime`, `RangeAttackTime`, `BaseVariance`, `RangeVariance`, `unit_class`, `unit_flags`, `unit_flags2`, `dynamicflags`, `family`, `type`, `type_flags`, `lootid`, `pickpocketloot`, `skinloot`, `PetSpellDataId`, `VehicleId`, `mingold`, `maxgold`, `AIName`, `MovementType`, `HoverHeight`, `HealthModifier`, `ManaModifier`, `ArmorModifier`, `ExperienceModifier`, `RacialLeader`, `movementId`, `RegenHealth`, `CreatureImmunitiesId`, `flags_extra`, `ScriptName`, `VerifiedBuild`)
  SELECT
    57524,
    `difficulty_entry_1`,
    `difficulty_entry_2`,
    `difficulty_entry_3`,
    `KillCredit1`,
    `KillCredit2`,
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
    `lootid`,
    `pickpocketloot`,
    `skinloot`,
    `PetSpellDataId`,
    `VehicleId`,
    `mingold`,
    `maxgold`,
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
  FROM `creature_template` WHERE `entry` = 57500;

UPDATE `creature_template` SET
  `name`           = 'Beginner''s Book of Artisans',
  `type`           = 10,
  `type_flags`     = 134217728,
  `HealthModifier` = 1.31781,
  -- the clone inherited the full book's UNIT_FLAG_NOT_SELECTABLE, see section 1
  `unit_flags`     = 768,
  -- stated again rather than left to the clone, so this row is right even if section 1 changes
  `npcflag`        = 177,
  `gossip_menu_id` = 57500
WHERE `entry` = 57524;

-- ---------------------------------------------------------------------------
-- 3. The model both books use, and its model info row
-- ---------------------------------------------------------------------------
-- Without a `creature_model_info` row the core cannot resolve the display and the creature
-- is dropped with "has no model ... can't load", which is why the row is part of the
-- restoration rather than an optimisation. 48503 is the same flat prop as 48501, whose row
-- the realm already carries, so it takes the same bounding radius, reach and gender ("none").
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (57500, 57524);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(57500, 0, 48503, 1, 1, NULL),
(57524, 0, 48503, 1, 1, NULL);

REPLACE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(48503, 0.01, 0.01, 2, 0);

-- ---------------------------------------------------------------------------
-- 4. Trainers: the full book keeps 200001, the beginner's gets its apprentice copy
-- ---------------------------------------------------------------------------
REPLACE INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES
(57500, 200001),
(57524, 200002);

-- Type 2 is a tradeskill trainer and the greeting is the realm's own line for the books.
REPLACE INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES
(200001, 2, 0, 'The knowledge of every craft is yours to claim, $N.', 0),
(200002, 2, 0, 'The knowledge of every craft is yours to claim, $N.', NULL);

-- ---------------------------------------------------------------------------
-- 4b. The list: the professions, and only the professions
-- ---------------------------------------------------------------------------
-- A trainer list is what its trainer teaches, and for a profession book that is the profession
-- itself: the rows that learn a trade and raise its ceiling. The recipes are not the book's
-- business - a pattern belongs to the trainer in the capital that teaches it, to the vendor that
-- sells it, or to the drop, the quest or the discovery it was earned from, and a book that lists
-- them is a book nobody can read: the realm's 200001 was holding 4739 rows, of which the
-- profession rows are 93.
--
-- The 93 rows below are the list itself rather than a filter over whatever a database happens to
-- hold: every spell of the client's own `Spell.dbc` whose effect 1, 2 or 3 is
--
--   44  SPELL_EFFECT_SKILL_STEP     the "Apprentice ... Grand Master <profession>" rows, which
--                                   learn the profession and raise its ceiling
--   47  SPELL_EFFECT_TRADE_SKILL    the trade-skill learn spells
--   118 SPELL_EFFECT_SKILL          a bare skill grant (CoA's Bushcraft)
--
-- and which the book already held. Fourteen professions at six ranks each - Apprentice,
-- Journeyman, Expert, Artisan, Master and Grand Master - plus CoA's own: Woodcutting and
-- Woodworking down to Artisan, and Bushcraft as a single grant. Nothing else in `trainer_spell`
-- is a profession row, so nothing else survives.
--
-- The book is the only place that teaches some of them: Bushcraft's single grant, and every rank
-- of Woodcutting and Woodworking up to Artisan, sit on no other trainer in the realm, so dropping
-- them would leave those three trades unreachable.
--
-- SQL cannot ask the client what a spell does, which is why the set is written out: the effects
-- live in `Spell.dbc`, the rows live here, and the two are kept in step by hand when the client's
-- spells change.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 200001;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`) VALUES
(200001, 2020, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2021, 0, 164, 50, 0, 0, 0, 0, 0),
(200001, 2154, 0, 165, 50, 0, 0, 0, 0, 0),
(200001, 2155, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2275, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2280, 0, 171, 50, 0, 0, 0, 0, 0),
(200001, 2372, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2373, 0, 182, 50, 0, 0, 0, 0, 0),
(200001, 2551, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2581, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 2582, 0, 186, 50, 0, 0, 0, 0, 0),
(200001, 3279, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 3280, 0, 129, 50, 0, 0, 0, 0, 0),
(200001, 3412, 0, 185, 50, 0, 0, 0, 0, 0),
(200001, 3465, 0, 171, 125, 0, 0, 0, 0, 0),
(200001, 3539, 0, 164, 125, 0, 0, 0, 0, 0),
(200001, 3568, 0, 186, 125, 0, 0, 0, 0, 0),
(200001, 3571, 0, 182, 125, 0, 0, 0, 0, 0),
(200001, 3812, 0, 165, 125, 0, 0, 0, 0, 0),
(200001, 3911, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 3912, 0, 197, 50, 0, 0, 0, 0, 0),
(200001, 3913, 0, 197, 125, 0, 0, 0, 0, 0),
(200001, 4039, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 4040, 0, 202, 50, 0, 0, 0, 0, 0),
(200001, 4041, 0, 202, 125, 0, 0, 0, 0, 0),
(200001, 7414, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 7415, 0, 333, 50, 0, 0, 0, 0, 0),
(200001, 7416, 0, 333, 125, 0, 0, 0, 0, 0),
(200001, 7733, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 7734, 0, 356, 50, 0, 0, 0, 0, 0),
(200001, 8615, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 8619, 0, 393, 50, 0, 0, 0, 0, 0),
(200001, 8620, 0, 393, 125, 0, 0, 0, 0, 0),
(200001, 9786, 0, 164, 200, 0, 0, 0, 0, 0),
(200001, 10249, 0, 186, 200, 0, 0, 0, 0, 0),
(200001, 10663, 0, 165, 200, 0, 0, 0, 0, 0),
(200001, 10769, 0, 393, 200, 0, 0, 0, 0, 0),
(200001, 10847, 0, 129, 200, 0, 0, 0, 0, 0),
(200001, 11612, 0, 171, 200, 0, 0, 0, 0, 0),
(200001, 11994, 0, 182, 200, 0, 0, 0, 0, 0),
(200001, 12181, 0, 197, 200, 0, 0, 0, 0, 0),
(200001, 12657, 0, 202, 200, 0, 0, 0, 0, 0),
(200001, 13921, 0, 333, 200, 0, 0, 0, 0, 0),
(200001, 18249, 0, 356, 200, 0, 0, 0, 0, 0),
(200001, 18261, 0, 185, 200, 0, 0, 0, 0, 0),
(200001, 25245, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 25246, 0, 755, 50, 0, 0, 0, 0, 0),
(200001, 26791, 0, 197, 275, 0, 0, 0, 0, 0),
(200001, 28030, 0, 333, 275, 0, 0, 0, 0, 0),
(200001, 28597, 0, 171, 275, 0, 0, 0, 0, 0),
(200001, 28696, 0, 182, 275, 0, 0, 0, 0, 0),
(200001, 28896, 0, 755, 125, 0, 0, 0, 0, 0),
(200001, 28899, 0, 755, 200, 0, 0, 0, 0, 0),
(200001, 28901, 0, 755, 275, 0, 0, 0, 0, 0),
(200001, 29355, 0, 186, 275, 0, 0, 0, 0, 0),
(200001, 29845, 0, 164, 275, 0, 0, 0, 0, 0),
(200001, 30351, 0, 202, 275, 0, 0, 0, 0, 0),
(200001, 32550, 0, 165, 275, 0, 0, 0, 0, 0),
(200001, 32679, 0, 393, 275, 0, 0, 0, 0, 0),
(200001, 45375, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 45376, 0, 773, 50, 0, 0, 0, 0, 0),
(200001, 45377, 0, 773, 125, 0, 0, 0, 0, 0),
(200001, 45378, 0, 773, 200, 0, 0, 0, 0, 0),
(200001, 45379, 0, 773, 275, 0, 0, 0, 0, 0),
(200001, 45380, 0, 773, 350, 0, 0, 0, 0, 0),
(200001, 50299, 0, 129, 350, 0, 0, 0, 0, 0),
(200001, 50301, 0, 182, 350, 0, 0, 0, 0, 0),
(200001, 50307, 0, 393, 350, 0, 0, 0, 0, 0),
(200001, 50309, 0, 186, 350, 0, 0, 0, 0, 0),
(200001, 51293, 0, 356, 350, 0, 0, 0, 0, 0),
(200001, 51295, 0, 185, 350, 0, 0, 0, 0, 0),
(200001, 51298, 0, 164, 350, 0, 0, 0, 0, 0),
(200001, 51301, 0, 165, 350, 0, 0, 0, 0, 0),
(200001, 51303, 0, 171, 350, 0, 0, 0, 0, 0),
(200001, 51308, 0, 197, 350, 0, 0, 0, 0, 0),
(200001, 51310, 0, 755, 350, 0, 0, 0, 0, 0),
(200001, 51312, 0, 333, 350, 0, 0, 0, 0, 0),
(200001, 54083, 0, 356, 125, 7731, 0, 0, 10, NULL),
(200001, 54084, 0, 356, 275, 18248, 0, 0, 10, NULL),
(200001, 54254, 0, 129, 125, 3274, 0, 0, 0, NULL),
(200001, 54255, 0, 129, 275, 10846, 0, 0, 0, NULL),
(200001, 54256, 0, 185, 275, 18260, 0, 0, 0, NULL),
(200001, 54257, 0, 185, 125, 3102, 0, 0, 0, NULL),
(200001, 61464, 0, 202, 350, 30350, 0, 0, 65, NULL),
(200001, 573523, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 1005014, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 1005015, 0, 757, 50, 0, 0, 0, 0, 0),
(200001, 1005016, 0, 757, 125, 0, 0, 0, 0, 0),
(200001, 1005017, 0, 757, 200, 0, 0, 0, 0, 0),
(200001, 13977880, 0, 0, 0, 0, 0, 0, 0, 0),
(200001, 13977885, 0, 732, 50, 0, 0, 0, 0, 0),
(200001, 13977886, 0, 732, 125, 0, 0, 0, 0, 0),
(200001, 13977887, 0, 732, 200, 0, 0, 0, 0, 0);

-- ---------------------------------------------------------------------------
-- 4c. The beginner's copy: the first rank of each profession, and nothing above it
-- ---------------------------------------------------------------------------
-- One row per profession - the rank that learns the trade - because that is what a beginner's
-- book is for: it teaches the entry step and leaves the ladder to the full book. `ReqSkillRank`
-- is 0 for exactly those rows: every apprentice rank, and Bushcraft's single grant.
DELETE FROM `trainer_spell` WHERE `TrainerId` = 200002;
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
  SELECT
    200002,
    `SpellId`,
    `MoneyCost`,
    `ReqSkillLine`,
    `ReqSkillRank`,
    `ReqAbility1`,
    `ReqAbility2`,
    `ReqAbility3`,
    `ReqLevel`,
    `VerifiedBuild`
  FROM `trainer_spell`
  WHERE `TrainerId` = 200001
    AND `ReqSkillRank` = 0;

-- ---------------------------------------------------------------------------
-- 5. The page a right click answers with, and the shelves behind its second option
-- ---------------------------------------------------------------------------
-- The page is the original's: a line about the book, then "I require training!" (the window
-- the module sends, filtered to the rows the character can train) and "I would like to browse
-- your goods." (a vendor list). The text is the one the live realm's client showed.
REPLACE INTO `npc_text` (`ID`, `text0_0`, `lang0`, `Probability0`, `VerifiedBuild`) VALUES
(57500, 'This book holds a seemingly endless amount of knowledge...', 0, 1, NULL);

REPLACE INTO `gossip_menu` (`MenuID`, `TextID`) VALUES (57500, 57500);

-- `OptionType` is the gossip action, and it is what the core hands a script as the option's
-- action (5 = GOSSIP_OPTION_TRAINER, 3 = GOSSIP_OPTION_VENDOR), so the module routes the
-- training option without depending on the ids. `OptionNpcFlag` is the flag the option is
-- offered under - the trainer bits and the vendor bit, both set on the creatures in section 1.
REPLACE INTO `gossip_menu_option` (`MenuID`, `OptionID`, `OptionIcon`, `OptionText`, `OptionBroadcastTextID`, `OptionType`, `OptionNpcFlag`, `ActionMenuID`, `ActionPoiID`, `BoxCoded`, `BoxMoney`, `BoxText`, `BoxBroadcastTextID`, `VerifiedBuild`) VALUES
(57500, 0, 3, 'I require training!', 0, 5, 48, 0, 0, 0, 0, NULL, 0, NULL),
(57500, 1, 1, 'I would like to browse your goods.', 0, 3, 128, 0, 0, 0, 0, NULL, 0, NULL);

-- The shelves are Edna Mullby's - entry 1286, "Trade Supplies" in Stormwind - row for row:
-- the thread, dye, vials, flux, coal, salt, stock, rods and tools a craftsperson buys while
-- levelling a profession, and the one limited-stock design she carries. `npc_vendor` holds no
-- price (it is the item's own `BuyPrice`, which the core and the client both read), so cloning
-- the rows is the whole of "the same items at the same prices". Her rows are never touched.
DELETE FROM `npc_vendor` WHERE `entry` IN (57500, 57524);
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
  SELECT 57500, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`
  FROM `npc_vendor` WHERE `entry` = 1286;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
  SELECT 57524, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`
  FROM `npc_vendor` WHERE `entry` = 1286;

-- ---------------------------------------------------------------------------
-- 6. The Beginner's Book of Artisans' one recovered spawn position
-- ---------------------------------------------------------------------------
-- 5300681 is the world database's own Book of Artisans, a full trainer left standing
-- outside the Northshire inn; 9000030 is the copy this file used to place. Neither belongs on
-- the map.
DELETE FROM `creature` WHERE `guid` IN (9000030, 9000031, 5300681);
INSERT INTO `creature` (`guid`, `id`, `map`, `zoneId`, `areaId`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `currentwaypoint`, `curhealth`, `curmana`, `MovementType`, `npcflag`, `unit_flags`, `dynamicflags`, `ScriptName`, `VerifiedBuild`, `CreateObject`, `Comment`) VALUES
(9000031, 57524, 1, 0, 0, 1, 1, 0, -887.072, -3778.650, 11.735, 2.531474, 300, 0, 0, 1, 0, 0, 0, 0, 0, '', NULL, 0, 'Beginner''s Book of Artisans: the archive''s example sighting in the Barrens');
