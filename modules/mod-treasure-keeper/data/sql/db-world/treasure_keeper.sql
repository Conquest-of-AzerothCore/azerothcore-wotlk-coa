-- mod-treasure-keeper - the data half of CoA's two bank companions.
--
-- Both companions are complete in this realm's data except for two values, and both gaps are
-- silent in play: one produces no packet at all, the other a pet three and a half times its
-- intended size.
--
-- 1. `npcflag`. The companions exist in `creature_template` with no flags whatsoever, so a right
--    click on the summoned pet has nothing to answer with. A banker carries
--    UNIT_NPC_FLAG_BANKER = 0x00020000 (131072): the client then offers the bank on the click
--    and sends the stock CMSG_BANKER_ACTIVATE (0x01B7), which the core answers with the native
--    bank window (SendShowBank). It must be that flag *alone* - a unit that also carries the
--    gossip flag is read by the client as a gossip NPC and never sends the banker click, which
--    is exactly the trap the Book of Artisans hit with its trainer flag.
--
--    `unit_flags` 768 (IMMUNE_TO_PC | IMMUNE_TO_NPC) is this realm's convention for the
--    interactable companions and props - the Book of Artisans and the restored Destiny Weavers
--    carry it - so the pet cannot be attacked or spell-targeted out from under the window.
--
-- 2. `creature_template_model`.`DisplayScale`. A creature's rendered size is the display's own
--    scale from the client's CreatureDisplayInfo.dbc multiplied by this column:
--
--        display 47857 (Celestial, Creature\CelestialHuman\CelestialHuman.m2)  client 3.5
--        display 48611 (wyrmtongue, Creature\wyrmtongue\wyrmtongue.mdx)        client 0.5
--
--    The plain keeper is therefore already right at 1.0 (a half-size wyrmtongue); the Celestial
--    one renders at 3.5x and reads as a giant. 0.1429 counters it to the same half-size as its
--    plain sibling. This is the one value here that no dump can confirm - the live server's
--    scale never reaches a client - so it is the value to adjust if the pet should sit larger;
--    0.2857 would put the Celestial at its model's natural (human) size instead.
--
-- Deliberately not touched: `type` (live caches say 7 Humanoid where these rows say 12
-- Non-combat Pet), `MovementType` (live movementId 999) and the items, spells, displays and
-- collection rows, all of which are already the realm's own. The items themselves are not sold,
-- dropped or rewarded anywhere: they are store/bundle grants ("Season 9 bundle exclusive").
--
-- Server-side behaviour lives in src/treasure_keeper.cpp: the startup readiness report, and the
-- summon restriction the item text advertises - refused in High-Risk Open World and War Mode, bound
-- to spells 93417 and 985356 below.

-- 1. The pets: a banker the client will offer, and nothing it can be killed through.
UPDATE `creature_template`
SET `npcflag` = 131072, `unit_flags` = 768
WHERE `entry` IN (80918, 10111377);

-- 2. The Celestial one next to its plain sibling: 3.5 x 0.1429 = 0.5, the wyrmtongue's own size.
UPDATE `creature_template_model`
SET `DisplayScale` = 0.1429
WHERE `CreatureID` = 80918 AND `Idx` = 0;

-- 3. Bind the two summon spells to the ruleset gate. A registered spell script runs only where
--    the database binds the spell to it, so without these rows the summons stay unrestricted.
DELETE FROM `spell_script_names` WHERE `ScriptName` = 'spell_treasure_keeper_summon';
INSERT INTO `spell_script_names` (`spell_id`, `ScriptName`) VALUES
(93417, 'spell_treasure_keeper_summon'),
(985356, 'spell_treasure_keeper_summon');
