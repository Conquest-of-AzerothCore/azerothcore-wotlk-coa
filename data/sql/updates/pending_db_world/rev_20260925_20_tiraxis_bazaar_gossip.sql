-- Tiraxis (900007) is the Ethereal Bazaar's scripted vendor again.
--
-- rev_20260918_20_books_of_ascension.sql rebuilt his template from entry 2672, which carries no
-- ScriptName, and gave him gossip menu 90007 with a single "browse your goods" option. That
-- replaced npc_tiraxis (mod-ethereal-bazaar), so the Bazaar, Convenience Items, Lost Caches,
-- Stones of Retreat and Heirlooms lists were gone. The script builds its own menu, so the
-- template gets the script back and no gossip menu.
UPDATE `creature_template` SET `ScriptName` = 'npc_tiraxis', `gossip_menu_id` = 0 WHERE `entry` = 900007;

-- The greeting's last line named the Ascension Shop, which this realm does not have.
UPDATE `npc_text` SET
    `text0_0` = REPLACE(`text0_0`, 'Ethereal Bazaar tokens are obtained via the auctionhouse and Ascension Shop.',
        'Bazaar Tokens can be gathered by killing creatures, completing quests and are offered in the auction house.'),
    `text0_1` = REPLACE(`text0_1`, 'Ethereal Bazaar tokens are obtained via the auctionhouse and Ascension Shop.',
        'Bazaar Tokens can be gathered by killing creatures, completing quests and are offered in the auction house.')
WHERE `ID` IN (900007, 90007);

-- One Tiraxis: the spawn the Books of Ascension update placed (9000001) stays.
DELETE FROM `creature` WHERE `id` = 900007 AND `guid` <> 9000001;
