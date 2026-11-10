-- Zul'Gurub Normal loot from the db.exil.es dump of 2026-10-04 and the CoA client caches: Hakkar's
-- Cache of the Blood God and Offering Key, one sigil per boss at 1 %, and one Edge of Madness blood item
-- per kill instead of up to three.
DELETE FROM `creature_loot_template` WHERE `Entry` = 14834 AND `Item` IN (1400023, 97725, 60108);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(14834, 1400023, 0, 100, 0, 1, 0, 1, 1, 'Hakkar - Cache of the Blood God'),
(14834, 97725, 0, 100, 0, 1, 0, 1, 1, 'Hakkar - Offering Key');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (14517, 14507, 14510, 14509, 14515, 11382, 11380, 14834, 15114, 15082, 15083, 15084, 15085)
    AND `Item` IN (60104, 60100, 60102, 60101, 60103, 59953, 59952, 60108, 60120, 60116, 60117, 60118, 60119);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(14517, 60104, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Jeklik - Sigil of High Priestess Jeklik'),
(14507, 60100, 0, 1, 0, 1, 0, 1, 1, 'High Priest Venoxis - Sigil of High Priest Venoxis'),
(14510, 60102, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Mar\'li - Sigil of High Priestess Mar\'li'),
(14509, 60101, 0, 1, 0, 1, 0, 1, 1, 'High Priest Thekal - Sigil of High Priest Thekal'),
(14515, 60103, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Arlokk - Sigil of High Priestess Arlokk'),
(11382, 59953, 0, 1, 0, 1, 0, 1, 1, 'Bloodlord Mandokir - Sigil of Bloodlord Mandokir'),
(11380, 59952, 0, 1, 0, 1, 0, 1, 1, 'Jin\'do the Hexxer - Sigil of Jin\'do the Hexxer'),
(14834, 60108, 0, 1, 0, 1, 0, 1, 1, 'Hakkar - Sigil of Hakkar'),
(15114, 60120, 0, 1, 0, 1, 0, 1, 1, 'Gahz\'ranka - Sigil of Gahz\'ranka'),
(15082, 60116, 0, 1, 0, 1, 0, 1, 1, 'Gri\'lek - Sigil of Gri\'lek'),
(15083, 60117, 0, 1, 0, 1, 0, 1, 1, 'Hazza\'rah - Sigil of Hazza\'rah'),
(15084, 60118, 0, 1, 0, 1, 0, 1, 1, 'Renataki - Sigil of Renataki'),
(15085, 60119, 0, 1, 0, 1, 0, 1, 1, 'Wushoolay - Sigil of Wushoolay');

DELETE FROM `creature_loot_template` WHERE `Entry` IN (15082, 15083, 15084, 15085) AND `Item` IN (19939, 19940, 19941, 19942)
    AND `GroupId` IN (3, 4);
