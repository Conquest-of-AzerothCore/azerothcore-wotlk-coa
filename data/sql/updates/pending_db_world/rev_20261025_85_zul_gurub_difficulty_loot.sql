-- Zul'Gurub loot on Heroic, Mythic and Ascended for the 13 bosses, from the per-difficulty boss loot
-- in the db.exil.es dump of 2026-10-04. Each variant gets its own loot id. Normalized as in
-- rev_20260930_80_molten_core_loot.sql: 0 % rows are dropped, guaranteed rows sit in group 0, and
-- items sharing one chance that adds up to 100 % form an equal-chance group. The Zandalar set
-- (19822-19849, 20033, 20034) and its tiered copies come from rev_20261025_93. Left out by decision:
-- the Battleweaver pieces (12390, 12391, 12473, 12503, 12504) and their tiered copies, and the
-- Dungeon Spoils 1202039/1027965. Hakkar's Ascended cache is 2500039 (Cache of the Blood God, Ascended). The dump has no Mythic Heart of Hakkar; 1319802 follows
-- the tier offset of the client item and quest 408183.
-- Trash variants keep the Normal loot id.

UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (
    111380, 111382, 114507, 114509, 114510, 114515, 114517, 114834, 115082, 115083, 115084, 115085,
    115114, 211380, 211382, 214507, 214509, 214510, 214515, 214517, 214834, 215082, 215083, 215084,
    215085, 215114, 311380, 311382, 314507, 314509, 314510, 314515, 314517, 314834, 315082, 315083,
    315084, 315085, 315114
);

DELETE FROM `creature_loot_template` WHERE `Entry` = 111380;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(111380, 319884, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Heroic) - Jin\'do\'s Judgement'),
(111380, 319885, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Heroic) - Jin\'do\'s Evil Eye'),
(111380, 319890, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Heroic) - Jin\'do\'s Hexxer'),
(111380, 319891, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Heroic) - Jin\'do\'s Bag of Whammies'),
(111380, 319875, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Bloodstained Coif'),
(111380, 319886, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - The Hexxer\'s Cover'),
(111380, 319887, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Bloodstained Legplates'),
(111380, 319888, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Overlord\'s Embrace'),
(111380, 319889, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Blooddrenched Leggings'),
(111380, 319892, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Animist\'s Boots'),
(111380, 319894, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Bloodsoaked Gauntlets'),
(111380, 319929, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Heroic) - Bloodtinged Gloves'),
(111380, 59952, 0, 1, 0, 1, 0, 1, 1, 'Jin\'do the Hexxer (Heroic) - Sigil of Jin\'do the Hexxer');

DELETE FROM `creature_loot_template` WHERE `Entry` = 111382;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(111382, 319866, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Heroic) - Warblade of the Hakkari'),
(111382, 319867, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Heroic) - Bloodlord\'s Defender'),
(111382, 319874, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Heroic) - Halberd of Smiting'),
(111382, 320038, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Heroic) - Mandokir\'s Sting'),
(111382, 319863, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Primalist\'s Seal'),
(111382, 319869, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Blooddrenched Grips'),
(111382, 319870, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Hakkari Loa Cloak'),
(111382, 319873, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Overlord\'s Crimson Band'),
(111382, 319877, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Animist\'s Leggings'),
(111382, 319878, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Bloodsoaked Pauldrons'),
(111382, 319893, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Zanzil\'s Seal'),
(111382, 319895, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Heroic) - Bloodtinged Kilt'),
(111382, 59953, 0, 1, 0, 1, 0, 1, 1, 'Bloodlord Mandokir (Heroic) - Sigil of Bloodlord Mandokir');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114507;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114507, 319900, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Zulian Stone Axe'),
(114507, 319903, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Fang of Venoxis'),
(114507, 319904, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Runed Bloodstained Hauberk'),
(114507, 319905, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Zanzil\'s Band'),
(114507, 319906, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Blooddrenched Footpads'),
(114507, 319907, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Heroic) - Zulian Tigerhide Cloak'),
(114507, 322711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Cloak of the Hakkari Worshippers'),
(114507, 322712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Might of the Tribe'),
(114507, 322713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Zulian Scepter of Rites'),
(114507, 322714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Sacrificial Gauntlets'),
(114507, 322715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Gloves of the Tormented'),
(114507, 322716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Belt of Untapped Power'),
(114507, 322718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Blooddrenched Mask'),
(114507, 322720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Zulian Headdress'),
(114507, 322721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Band of Servitude'),
(114507, 322722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Heroic) - Seal of the Gurubashi Berserker'),
(114507, 60100, 0, 1, 0, 1, 0, 1, 1, 'High Priest Venoxis (Heroic) - Sigil of High Priest Venoxis');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114509;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114509, 319896, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Thekal\'s Grasp'),
(114509, 319897, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Betrayer\'s Boots'),
(114509, 319898, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Seal of Jin'),
(114509, 319899, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Ritualistic Legguards'),
(114509, 319901, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Zulian Slicer'),
(114509, 320260, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Seafury Leggings'),
(114509, 320266, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Heroic) - Peacekeeper Leggings'),
(114509, 322711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Cloak of the Hakkari Worshippers'),
(114509, 322712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Might of the Tribe'),
(114509, 322713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Zulian Scepter of Rites'),
(114509, 322714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Sacrificial Gauntlets'),
(114509, 322715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Gloves of the Tormented'),
(114509, 322716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Belt of Untapped Power'),
(114509, 322718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Blooddrenched Mask'),
(114509, 322720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Zulian Headdress'),
(114509, 322721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Band of Servitude'),
(114509, 322722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Heroic) - Seal of the Gurubashi Berserker'),
(114509, 60101, 0, 1, 0, 1, 0, 1, 1, 'High Priest Thekal (Heroic) - Sigil of High Priest Thekal');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114510;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114510, 319871, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Talisman of Protection'),
(114510, 319919, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Bloodstained Greaves'),
(114510, 319925, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Band of Jin'),
(114510, 319927, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Mar\'li\'s Touch'),
(114510, 319930, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Mar\'li\'s Eye'),
(114510, 320032, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Heroic) - Flowing Ritual Robes'),
(114510, 322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Cloak of the Hakkari Worshippers'),
(114510, 322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Might of the Tribe'),
(114510, 322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Zulian Scepter of Rites'),
(114510, 322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Sacrificial Gauntlets'),
(114510, 322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Gloves of the Tormented'),
(114510, 322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Belt of Untapped Power'),
(114510, 322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Blooddrenched Mask'),
(114510, 322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Zulian Headdress'),
(114510, 322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Band of Servitude'),
(114510, 322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Heroic) - Seal of the Gurubashi Berserker'),
(114510, 60102, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Mar\'li (Heroic) - Sigil of High Priestess Mar\'li');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114515;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114515, 319909, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Heroic) - Will of Arlokk'),
(114515, 319910, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Heroic) - Arlokk\'s Grasp'),
(114515, 319912, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Heroic) - Overlord\'s Onyx Band'),
(114515, 319913, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Heroic) - Bloodsoaked Greaves'),
(114515, 319922, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Heroic) - Arlokk\'s Hoodoo Stick'),
(114515, 322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Cloak of the Hakkari Worshippers'),
(114515, 322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Might of the Tribe'),
(114515, 322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Zulian Scepter of Rites'),
(114515, 322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Sacrificial Gauntlets'),
(114515, 322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Gloves of the Tormented'),
(114515, 322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Belt of Untapped Power'),
(114515, 322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Blooddrenched Mask'),
(114515, 322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Zulian Headdress'),
(114515, 322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Band of Servitude'),
(114515, 322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Heroic) - Seal of the Gurubashi Berserker'),
(114515, 60103, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Arlokk (Heroic) - Sigil of High Priestess Arlokk');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114517;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114517, 319915, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Zulian Defender'),
(114517, 319918, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Jeklik\'s Crusher'),
(114517, 319920, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Primalist\'s Band'),
(114517, 319923, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Jeklik\'s Opaline Talisman'),
(114517, 319928, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Animist\'s Spaulders'),
(114517, 320262, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Seafury Boots'),
(114517, 320265, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Heroic) - Peacekeeper Boots'),
(114517, 322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Cloak of the Hakkari Worshippers'),
(114517, 322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Might of the Tribe'),
(114517, 322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Zulian Scepter of Rites'),
(114517, 322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Sacrificial Gauntlets'),
(114517, 322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Gloves of the Tormented'),
(114517, 322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Belt of Untapped Power'),
(114517, 322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Blooddrenched Mask'),
(114517, 322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Zulian Headdress'),
(114517, 322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Band of Servitude'),
(114517, 322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Heroic) - Seal of the Gurubashi Berserker'),
(114517, 60104, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Jeklik (Heroic) - Sigil of High Priestess Jeklik');

DELETE FROM `creature_loot_template` WHERE `Entry` = 114834;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(114834, 97725, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Heroic) - Offering Key'),
(114834, 319802, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Heroic) - Heart of Hakkar'),
(114834, 1400039, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Heroic) - Cache of the Blood God'),
(114834, 319852, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Ancient Hakkari Manslayer'),
(114834, 319853, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Gurubashi Dwarf Destroyer'),
(114834, 319854, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Zin\'rokh, Destroyer of Worlds'),
(114834, 319855, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Bloodsoaked Legplates'),
(114834, 319856, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - The Eye of Hakkar'),
(114834, 319857, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Cloak of Consumption'),
(114834, 319859, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Fang of the Faceless'),
(114834, 319861, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Touch of Chaos'),
(114834, 319862, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Aegis of the Blood God'),
(114834, 319864, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Bloodcaller'),
(114834, 319865, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Warblade of the Hakkari'),
(114834, 319876, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Soul Corrupter\'s Necklace'),
(114834, 320257, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Seafury Gauntlets'),
(114834, 320264, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Heroic) - Peacekeeper Gauntlets'),
(114834, 60108, 0, 1, 0, 1, 0, 1, 1, 'Hakkar (Heroic) - Sigil of Hakkar');

DELETE FROM `creature_loot_template` WHERE `Entry` = 115082;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(115082, 319951, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Gri\'lek\'s Charm of Might'),
(115082, 319952, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Gri\'lek\'s Charm of Valor'),
(115082, 319953, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Renataki\'s Charm of Beasts'),
(115082, 319954, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Renataki\'s Charm of Trickery'),
(115082, 319955, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Wushoolay\'s Charm of Nature'),
(115082, 319956, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Wushoolay\'s Charm of Spirits'),
(115082, 319957, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Hazza\'rah\'s Charm of Destruction'),
(115082, 319958, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Hazza\'rah\'s Charm of Healing'),
(115082, 319959, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Hazza\'rah\'s Charm of Magic'),
(115082, 319961, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Gri\'lek\'s Grinder'),
(115082, 319962, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Gri\'lek\'s Carver'),
(115082, 319963, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Pitchfork of Madness'),
(115082, 319964, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Renataki\'s Soul Conduit'),
(115082, 319965, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Wushoolay\'s Poker'),
(115082, 319967, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Thoughtblighter'),
(115082, 319968, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Fiery Retributer'),
(115082, 319993, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Hoodoo Hunting Bow'),
(115082, 60116, 0, 1, 0, 1, 0, 1, 1, 'Gri\'lek (Heroic) - Sigil of Gri\'lek');

DELETE FROM `creature_loot_template` WHERE `Entry` = 115083;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(115083, 319951, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Gri\'lek\'s Charm of Might'),
(115083, 319952, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Gri\'lek\'s Charm of Valor'),
(115083, 319953, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Renataki\'s Charm of Beasts'),
(115083, 319954, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Renataki\'s Charm of Trickery'),
(115083, 319955, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Wushoolay\'s Charm of Nature'),
(115083, 319956, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Wushoolay\'s Charm of Spirits'),
(115083, 319957, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Hazza\'rah\'s Charm of Destruction'),
(115083, 319958, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Hazza\'rah\'s Charm of Healing'),
(115083, 319959, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Hazza\'rah\'s Charm of Magic'),
(115083, 319961, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Gri\'lek\'s Grinder'),
(115083, 319962, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Gri\'lek\'s Carver'),
(115083, 319963, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Pitchfork of Madness'),
(115083, 319964, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Renataki\'s Soul Conduit'),
(115083, 319965, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Wushoolay\'s Poker'),
(115083, 319967, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Thoughtblighter'),
(115083, 319968, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Fiery Retributer'),
(115083, 319993, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Hoodoo Hunting Bow'),
(115083, 60117, 0, 1, 0, 1, 0, 1, 1, 'Hazza\'rah (Heroic) - Sigil of Hazza\'rah');

DELETE FROM `creature_loot_template` WHERE `Entry` = 115084;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(115084, 319951, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Gri\'lek\'s Charm of Might'),
(115084, 319952, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Gri\'lek\'s Charm of Valor'),
(115084, 319953, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Renataki\'s Charm of Beasts'),
(115084, 319954, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Renataki\'s Charm of Trickery'),
(115084, 319955, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Wushoolay\'s Charm of Nature'),
(115084, 319956, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Wushoolay\'s Charm of Spirits'),
(115084, 319957, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Hazza\'rah\'s Charm of Destruction'),
(115084, 319958, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Hazza\'rah\'s Charm of Healing'),
(115084, 319959, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Hazza\'rah\'s Charm of Magic'),
(115084, 319961, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Gri\'lek\'s Grinder'),
(115084, 319962, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Gri\'lek\'s Carver'),
(115084, 319963, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Pitchfork of Madness'),
(115084, 319964, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Renataki\'s Soul Conduit'),
(115084, 319965, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Wushoolay\'s Poker'),
(115084, 319967, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Thoughtblighter'),
(115084, 319968, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Fiery Retributer'),
(115084, 319993, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Hoodoo Hunting Bow'),
(115084, 60118, 0, 1, 0, 1, 0, 1, 1, 'Renataki (Heroic) - Sigil of Renataki');

DELETE FROM `creature_loot_template` WHERE `Entry` = 115085;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(115085, 319951, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Gri\'lek\'s Charm of Might'),
(115085, 319952, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Gri\'lek\'s Charm of Valor'),
(115085, 319953, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Renataki\'s Charm of Beasts'),
(115085, 319954, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Renataki\'s Charm of Trickery'),
(115085, 319955, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Wushoolay\'s Charm of Nature'),
(115085, 319956, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Wushoolay\'s Charm of Spirits'),
(115085, 319957, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Hazza\'rah\'s Charm of Destruction'),
(115085, 319958, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Hazza\'rah\'s Charm of Healing'),
(115085, 319959, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Hazza\'rah\'s Charm of Magic'),
(115085, 319961, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Gri\'lek\'s Grinder'),
(115085, 319962, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Gri\'lek\'s Carver'),
(115085, 319963, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Pitchfork of Madness'),
(115085, 319964, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Renataki\'s Soul Conduit'),
(115085, 319965, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Wushoolay\'s Poker'),
(115085, 319967, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Thoughtblighter'),
(115085, 319968, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Fiery Retributer'),
(115085, 319993, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Hoodoo Hunting Bow'),
(115085, 60119, 0, 1, 0, 1, 0, 1, 1, 'Wushoolay (Heroic) - Sigil of Wushoolay');

DELETE FROM `creature_loot_template` WHERE `Entry` = 115114;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(115114, 319944, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Nat Pagle\'s Fish Terminator'),
(115114, 319945, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Foror\'s Eyepatch'),
(115114, 319946, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Tigule\'s Harpoon'),
(115114, 319947, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Nat Pagle\'s Broken Reel'),
(115114, 319908, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Sceptre of Smiting'),
(115114, 319921, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Zulian Hacker'),
(115114, 320258, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Zulian Ceremonial Staff'),
(115114, 320259, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Shadow Panther Hide Gloves'),
(115114, 320261, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Shadow Panther Hide Belt'),
(115114, 320263, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Heroic) - Gurubashi Helm'),
(115114, 1022739, 0, 5, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Tome of Polymorph: Turtle'),
(115114, 60120, 0, 1, 0, 1, 0, 1, 1, 'Gahz\'ranka (Heroic) - Sigil of Gahz\'ranka');

DELETE FROM `creature_loot_template` WHERE `Entry` = 211380;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(211380, 1319884, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Mythic) - Jin\'do\'s Judgement'),
(211380, 1319885, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Mythic) - Jin\'do\'s Evil Eye'),
(211380, 1319890, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Mythic) - Jin\'do\'s Hexxer'),
(211380, 1319891, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Mythic) - Jin\'do\'s Bag of Whammies'),
(211380, 1319875, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Bloodstained Coif'),
(211380, 1319886, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - The Hexxer\'s Cover'),
(211380, 1319887, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Bloodstained Legplates'),
(211380, 1319888, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Overlord\'s Embrace'),
(211380, 1319889, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Blooddrenched Leggings'),
(211380, 1319892, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Animist\'s Boots'),
(211380, 1319894, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Bloodsoaked Gauntlets'),
(211380, 1319929, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Mythic) - Bloodtinged Gloves'),
(211380, 59952, 0, 1, 0, 1, 0, 1, 1, 'Jin\'do the Hexxer (Mythic) - Sigil of Jin\'do the Hexxer');

DELETE FROM `creature_loot_template` WHERE `Entry` = 211382;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(211382, 1319866, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Mythic) - Warblade of the Hakkari'),
(211382, 1319867, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Mythic) - Bloodlord\'s Defender'),
(211382, 1319874, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Mythic) - Halberd of Smiting'),
(211382, 1320038, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Mythic) - Mandokir\'s Sting'),
(211382, 1319863, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Primalist\'s Seal'),
(211382, 1319869, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Blooddrenched Grips'),
(211382, 1319870, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Hakkari Loa Cloak'),
(211382, 1319873, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Overlord\'s Crimson Band'),
(211382, 1319877, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Animist\'s Leggings'),
(211382, 1319878, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Bloodsoaked Pauldrons'),
(211382, 1319893, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Zanzil\'s Seal'),
(211382, 1319895, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Mythic) - Bloodtinged Kilt'),
(211382, 59953, 0, 1, 0, 1, 0, 1, 1, 'Bloodlord Mandokir (Mythic) - Sigil of Bloodlord Mandokir');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214507;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214507, 1319900, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Zulian Stone Axe'),
(214507, 1319903, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Fang of Venoxis'),
(214507, 1319904, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Runed Bloodstained Hauberk'),
(214507, 1319905, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Zanzil\'s Band'),
(214507, 1319906, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Blooddrenched Footpads'),
(214507, 1319907, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Mythic) - Zulian Tigerhide Cloak'),
(214507, 1322711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Cloak of the Hakkari Worshippers'),
(214507, 1322712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Might of the Tribe'),
(214507, 1322713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Zulian Scepter of Rites'),
(214507, 1322714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Sacrificial Gauntlets'),
(214507, 1322715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Gloves of the Tormented'),
(214507, 1322716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Belt of Untapped Power'),
(214507, 1322718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Blooddrenched Mask'),
(214507, 1322720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Zulian Headdress'),
(214507, 1322721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Band of Servitude'),
(214507, 1322722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Mythic) - Seal of the Gurubashi Berserker'),
(214507, 60100, 0, 1, 0, 1, 0, 1, 1, 'High Priest Venoxis (Mythic) - Sigil of High Priest Venoxis');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214509;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214509, 1319896, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Thekal\'s Grasp'),
(214509, 1319897, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Betrayer\'s Boots'),
(214509, 1319898, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Seal of Jin'),
(214509, 1319899, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Ritualistic Legguards'),
(214509, 1319901, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Zulian Slicer'),
(214509, 1320260, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Seafury Leggings'),
(214509, 1320266, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Mythic) - Peacekeeper Leggings'),
(214509, 1322711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Cloak of the Hakkari Worshippers'),
(214509, 1322712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Might of the Tribe'),
(214509, 1322713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Zulian Scepter of Rites'),
(214509, 1322714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Sacrificial Gauntlets'),
(214509, 1322715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Gloves of the Tormented'),
(214509, 1322716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Belt of Untapped Power'),
(214509, 1322718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Blooddrenched Mask'),
(214509, 1322720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Zulian Headdress'),
(214509, 1322721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Band of Servitude'),
(214509, 1322722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Mythic) - Seal of the Gurubashi Berserker'),
(214509, 60101, 0, 1, 0, 1, 0, 1, 1, 'High Priest Thekal (Mythic) - Sigil of High Priest Thekal');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214510;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214510, 1319871, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Talisman of Protection'),
(214510, 1319919, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Bloodstained Greaves'),
(214510, 1319925, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Band of Jin'),
(214510, 1319927, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Mar\'li\'s Touch'),
(214510, 1319930, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Mar\'li\'s Eye'),
(214510, 1320032, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Mythic) - Flowing Ritual Robes'),
(214510, 1322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Cloak of the Hakkari Worshippers'),
(214510, 1322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Might of the Tribe'),
(214510, 1322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Zulian Scepter of Rites'),
(214510, 1322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Sacrificial Gauntlets'),
(214510, 1322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Gloves of the Tormented'),
(214510, 1322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Belt of Untapped Power'),
(214510, 1322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Blooddrenched Mask'),
(214510, 1322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Zulian Headdress'),
(214510, 1322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Band of Servitude'),
(214510, 1322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Mythic) - Seal of the Gurubashi Berserker'),
(214510, 60102, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Mar\'li (Mythic) - Sigil of High Priestess Mar\'li');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214515;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214515, 1319909, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Mythic) - Will of Arlokk'),
(214515, 1319910, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Mythic) - Arlokk\'s Grasp'),
(214515, 1319912, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Mythic) - Overlord\'s Onyx Band'),
(214515, 1319913, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Mythic) - Bloodsoaked Greaves'),
(214515, 1319922, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Mythic) - Arlokk\'s Hoodoo Stick'),
(214515, 1322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Cloak of the Hakkari Worshippers'),
(214515, 1322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Might of the Tribe'),
(214515, 1322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Zulian Scepter of Rites'),
(214515, 1322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Sacrificial Gauntlets'),
(214515, 1322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Gloves of the Tormented'),
(214515, 1322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Belt of Untapped Power'),
(214515, 1322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Blooddrenched Mask'),
(214515, 1322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Zulian Headdress'),
(214515, 1322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Band of Servitude'),
(214515, 1322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Mythic) - Seal of the Gurubashi Berserker'),
(214515, 60103, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Arlokk (Mythic) - Sigil of High Priestess Arlokk');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214517;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214517, 1319915, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Zulian Defender'),
(214517, 1319918, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Jeklik\'s Crusher'),
(214517, 1319920, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Primalist\'s Band'),
(214517, 1319923, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Jeklik\'s Opaline Talisman'),
(214517, 1319928, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Animist\'s Spaulders'),
(214517, 1320262, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Seafury Boots'),
(214517, 1320265, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Mythic) - Peacekeeper Boots'),
(214517, 1322711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Cloak of the Hakkari Worshippers'),
(214517, 1322712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Might of the Tribe'),
(214517, 1322713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Zulian Scepter of Rites'),
(214517, 1322714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Sacrificial Gauntlets'),
(214517, 1322715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Gloves of the Tormented'),
(214517, 1322716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Belt of Untapped Power'),
(214517, 1322718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Blooddrenched Mask'),
(214517, 1322720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Zulian Headdress'),
(214517, 1322721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Band of Servitude'),
(214517, 1322722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Mythic) - Seal of the Gurubashi Berserker'),
(214517, 60104, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Jeklik (Mythic) - Sigil of High Priestess Jeklik');

DELETE FROM `creature_loot_template` WHERE `Entry` = 214834;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(214834, 97725, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Mythic) - Offering Key'),
(214834, 1319802, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Mythic) - Heart of Hakkar'),
(214834, 2400039, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Mythic) - Cache of the Blood God'),
(214834, 1319852, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Ancient Hakkari Manslayer'),
(214834, 1319853, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Gurubashi Dwarf Destroyer'),
(214834, 1319854, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Zin\'rokh, Destroyer of Worlds'),
(214834, 1319855, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Bloodsoaked Legplates'),
(214834, 1319856, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - The Eye of Hakkar'),
(214834, 1319857, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Cloak of Consumption'),
(214834, 1319859, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Fang of the Faceless'),
(214834, 1319861, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Touch of Chaos'),
(214834, 1319862, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Aegis of the Blood God'),
(214834, 1319864, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Bloodcaller'),
(214834, 1319865, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Warblade of the Hakkari'),
(214834, 1319876, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Soul Corrupter\'s Necklace'),
(214834, 1320257, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Seafury Gauntlets'),
(214834, 1320264, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Mythic) - Peacekeeper Gauntlets'),
(214834, 60108, 0, 1, 0, 1, 0, 1, 1, 'Hakkar (Mythic) - Sigil of Hakkar');

DELETE FROM `creature_loot_template` WHERE `Entry` = 215082;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(215082, 1319951, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Gri\'lek\'s Charm of Might'),
(215082, 1319952, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Gri\'lek\'s Charm of Valor'),
(215082, 1319953, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Renataki\'s Charm of Beasts'),
(215082, 1319954, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Renataki\'s Charm of Trickery'),
(215082, 1319955, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Wushoolay\'s Charm of Nature'),
(215082, 1319956, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Wushoolay\'s Charm of Spirits'),
(215082, 1319957, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Hazza\'rah\'s Charm of Destruction'),
(215082, 1319958, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Hazza\'rah\'s Charm of Healing'),
(215082, 1319959, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Hazza\'rah\'s Charm of Magic'),
(215082, 1319961, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Gri\'lek\'s Grinder'),
(215082, 1319962, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Gri\'lek\'s Carver'),
(215082, 1319963, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Pitchfork of Madness'),
(215082, 1319964, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Renataki\'s Soul Conduit'),
(215082, 1319965, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Wushoolay\'s Poker'),
(215082, 1319967, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Thoughtblighter'),
(215082, 1319968, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Fiery Retributer'),
(215082, 1319993, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Hoodoo Hunting Bow'),
(215082, 60116, 0, 1, 0, 1, 0, 1, 1, 'Gri\'lek (Mythic) - Sigil of Gri\'lek');

DELETE FROM `creature_loot_template` WHERE `Entry` = 215083;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(215083, 1319951, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Gri\'lek\'s Charm of Might'),
(215083, 1319952, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Gri\'lek\'s Charm of Valor'),
(215083, 1319953, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Renataki\'s Charm of Beasts'),
(215083, 1319954, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Renataki\'s Charm of Trickery'),
(215083, 1319955, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Wushoolay\'s Charm of Nature'),
(215083, 1319956, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Wushoolay\'s Charm of Spirits'),
(215083, 1319957, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Hazza\'rah\'s Charm of Destruction'),
(215083, 1319958, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Hazza\'rah\'s Charm of Healing'),
(215083, 1319959, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Hazza\'rah\'s Charm of Magic'),
(215083, 1319961, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Gri\'lek\'s Grinder'),
(215083, 1319962, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Gri\'lek\'s Carver'),
(215083, 1319963, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Pitchfork of Madness'),
(215083, 1319964, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Renataki\'s Soul Conduit'),
(215083, 1319965, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Wushoolay\'s Poker'),
(215083, 1319967, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Thoughtblighter'),
(215083, 1319968, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Fiery Retributer'),
(215083, 1319993, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Hoodoo Hunting Bow'),
(215083, 60117, 0, 1, 0, 1, 0, 1, 1, 'Hazza\'rah (Mythic) - Sigil of Hazza\'rah');

DELETE FROM `creature_loot_template` WHERE `Entry` = 215084;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(215084, 1319951, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Gri\'lek\'s Charm of Might'),
(215084, 1319952, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Gri\'lek\'s Charm of Valor'),
(215084, 1319953, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Renataki\'s Charm of Beasts'),
(215084, 1319954, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Renataki\'s Charm of Trickery'),
(215084, 1319955, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Wushoolay\'s Charm of Nature'),
(215084, 1319956, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Wushoolay\'s Charm of Spirits'),
(215084, 1319957, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Hazza\'rah\'s Charm of Destruction'),
(215084, 1319958, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Hazza\'rah\'s Charm of Healing'),
(215084, 1319959, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Hazza\'rah\'s Charm of Magic'),
(215084, 1319961, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Gri\'lek\'s Grinder'),
(215084, 1319962, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Gri\'lek\'s Carver'),
(215084, 1319963, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Pitchfork of Madness'),
(215084, 1319964, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Renataki\'s Soul Conduit'),
(215084, 1319965, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Wushoolay\'s Poker'),
(215084, 1319967, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Thoughtblighter'),
(215084, 1319968, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Fiery Retributer'),
(215084, 1319993, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Hoodoo Hunting Bow'),
(215084, 60118, 0, 1, 0, 1, 0, 1, 1, 'Renataki (Mythic) - Sigil of Renataki');

DELETE FROM `creature_loot_template` WHERE `Entry` = 215085;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(215085, 1319951, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Gri\'lek\'s Charm of Might'),
(215085, 1319952, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Gri\'lek\'s Charm of Valor'),
(215085, 1319953, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Renataki\'s Charm of Beasts'),
(215085, 1319954, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Renataki\'s Charm of Trickery'),
(215085, 1319955, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Wushoolay\'s Charm of Nature'),
(215085, 1319956, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Wushoolay\'s Charm of Spirits'),
(215085, 1319957, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Hazza\'rah\'s Charm of Destruction'),
(215085, 1319958, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Hazza\'rah\'s Charm of Healing'),
(215085, 1319959, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Hazza\'rah\'s Charm of Magic'),
(215085, 1319961, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Gri\'lek\'s Grinder'),
(215085, 1319962, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Gri\'lek\'s Carver'),
(215085, 1319963, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Pitchfork of Madness'),
(215085, 1319964, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Renataki\'s Soul Conduit'),
(215085, 1319965, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Wushoolay\'s Poker'),
(215085, 1319967, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Thoughtblighter'),
(215085, 1319968, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Fiery Retributer'),
(215085, 1319993, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Hoodoo Hunting Bow'),
(215085, 60119, 0, 1, 0, 1, 0, 1, 1, 'Wushoolay (Mythic) - Sigil of Wushoolay');

DELETE FROM `creature_loot_template` WHERE `Entry` = 215114;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(215114, 1319944, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Nat Pagle\'s Fish Terminator'),
(215114, 1319945, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Foror\'s Eyepatch'),
(215114, 1319946, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Tigule\'s Harpoon'),
(215114, 1319947, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Nat Pagle\'s Broken Reel'),
(215114, 1319908, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Sceptre of Smiting'),
(215114, 1319921, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Zulian Hacker'),
(215114, 1320258, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Zulian Ceremonial Staff'),
(215114, 1320259, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Shadow Panther Hide Gloves'),
(215114, 1320261, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Shadow Panther Hide Belt'),
(215114, 1320263, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Mythic) - Gurubashi Helm'),
(215114, 1022739, 0, 10, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Tome of Polymorph: Turtle'),
(215114, 60120, 0, 1, 0, 1, 0, 1, 1, 'Gahz\'ranka (Mythic) - Sigil of Gahz\'ranka');

DELETE FROM `creature_loot_template` WHERE `Entry` = 311380;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(311380, 219884, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Ascended) - Jin\'do\'s Judgement'),
(311380, 219885, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Ascended) - Jin\'do\'s Evil Eye'),
(311380, 219890, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Ascended) - Jin\'do\'s Hexxer'),
(311380, 219891, 0, 0, 0, 1, 1, 1, 1, 'Jin\'do the Hexxer (Ascended) - Jin\'do\'s Bag of Whammies'),
(311380, 219875, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Bloodstained Coif'),
(311380, 219886, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - The Hexxer\'s Cover'),
(311380, 219887, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Bloodstained Legplates'),
(311380, 219888, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Overlord\'s Embrace'),
(311380, 219889, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Blooddrenched Leggings'),
(311380, 219892, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Animist\'s Boots'),
(311380, 219894, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Bloodsoaked Gauntlets'),
(311380, 219929, 0, 0, 0, 1, 2, 1, 1, 'Jin\'do the Hexxer (Ascended) - Bloodtinged Gloves'),
(311380, 59952, 0, 1, 0, 1, 0, 1, 1, 'Jin\'do the Hexxer (Ascended) - Sigil of Jin\'do the Hexxer');

DELETE FROM `creature_loot_template` WHERE `Entry` = 311382;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(311382, 219866, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Ascended) - Warblade of the Hakkari'),
(311382, 219867, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Ascended) - Bloodlord\'s Defender'),
(311382, 219874, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Ascended) - Halberd of Smiting'),
(311382, 220038, 0, 0, 0, 1, 1, 1, 1, 'Bloodlord Mandokir (Ascended) - Mandokir\'s Sting'),
(311382, 219863, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Primalist\'s Seal'),
(311382, 219869, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Blooddrenched Grips'),
(311382, 219870, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Hakkari Loa Cloak'),
(311382, 219873, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Overlord\'s Crimson Band'),
(311382, 219877, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Animist\'s Leggings'),
(311382, 219878, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Bloodsoaked Pauldrons'),
(311382, 219893, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Zanzil\'s Seal'),
(311382, 219895, 0, 0, 0, 1, 2, 1, 1, 'Bloodlord Mandokir (Ascended) - Bloodtinged Kilt'),
(311382, 59953, 0, 1, 0, 1, 0, 1, 1, 'Bloodlord Mandokir (Ascended) - Sigil of Bloodlord Mandokir');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314507;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314507, 219900, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Zulian Stone Axe'),
(314507, 219903, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Fang of Venoxis'),
(314507, 219904, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Runed Bloodstained Hauberk'),
(314507, 219905, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Zanzil\'s Band'),
(314507, 219906, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Blooddrenched Footpads'),
(314507, 219907, 0, 0, 0, 1, 1, 1, 1, 'High Priest Venoxis (Ascended) - Zulian Tigerhide Cloak'),
(314507, 222711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Cloak of the Hakkari Worshippers'),
(314507, 222712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Might of the Tribe'),
(314507, 222713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Zulian Scepter of Rites'),
(314507, 222714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Sacrificial Gauntlets'),
(314507, 222715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Gloves of the Tormented'),
(314507, 222716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Belt of Untapped Power'),
(314507, 222718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Blooddrenched Mask'),
(314507, 222720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Zulian Headdress'),
(314507, 222721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Band of Servitude'),
(314507, 222722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Venoxis (Ascended) - Seal of the Gurubashi Berserker'),
(314507, 60100, 0, 1, 0, 1, 0, 1, 1, 'High Priest Venoxis (Ascended) - Sigil of High Priest Venoxis');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314509;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314509, 219896, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Thekal\'s Grasp'),
(314509, 219897, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Betrayer\'s Boots'),
(314509, 219898, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Seal of Jin'),
(314509, 219899, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Ritualistic Legguards'),
(314509, 219901, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Zulian Slicer'),
(314509, 220260, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Seafury Leggings'),
(314509, 220266, 0, 0, 0, 1, 1, 1, 1, 'High Priest Thekal (Ascended) - Peacekeeper Leggings'),
(314509, 222711, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Cloak of the Hakkari Worshippers'),
(314509, 222712, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Might of the Tribe'),
(314509, 222713, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Zulian Scepter of Rites'),
(314509, 222714, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Sacrificial Gauntlets'),
(314509, 222715, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Gloves of the Tormented'),
(314509, 222716, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Belt of Untapped Power'),
(314509, 222718, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Blooddrenched Mask'),
(314509, 222720, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Zulian Headdress'),
(314509, 222721, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Band of Servitude'),
(314509, 222722, 0, 0, 0, 1, 2, 1, 1, 'High Priest Thekal (Ascended) - Seal of the Gurubashi Berserker'),
(314509, 60101, 0, 1, 0, 1, 0, 1, 1, 'High Priest Thekal (Ascended) - Sigil of High Priest Thekal');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314510;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314510, 219871, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Talisman of Protection'),
(314510, 219919, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Bloodstained Greaves'),
(314510, 219925, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Band of Jin'),
(314510, 219927, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Mar\'li\'s Touch'),
(314510, 219930, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Mar\'li\'s Eye'),
(314510, 220032, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Mar\'li (Ascended) - Flowing Ritual Robes'),
(314510, 222711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Cloak of the Hakkari Worshippers'),
(314510, 222712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Might of the Tribe'),
(314510, 222713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Zulian Scepter of Rites'),
(314510, 222714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Sacrificial Gauntlets'),
(314510, 222715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Gloves of the Tormented'),
(314510, 222716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Belt of Untapped Power'),
(314510, 222718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Blooddrenched Mask'),
(314510, 222720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Zulian Headdress'),
(314510, 222721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Band of Servitude'),
(314510, 222722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Mar\'li (Ascended) - Seal of the Gurubashi Berserker'),
(314510, 60102, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Mar\'li (Ascended) - Sigil of High Priestess Mar\'li');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314515;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314515, 219909, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Ascended) - Will of Arlokk'),
(314515, 219910, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Ascended) - Arlokk\'s Grasp'),
(314515, 219912, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Ascended) - Overlord\'s Onyx Band'),
(314515, 219913, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Ascended) - Bloodsoaked Greaves'),
(314515, 219922, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Arlokk (Ascended) - Arlokk\'s Hoodoo Stick'),
(314515, 222711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Cloak of the Hakkari Worshippers'),
(314515, 222712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Might of the Tribe'),
(314515, 222713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Zulian Scepter of Rites'),
(314515, 222714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Sacrificial Gauntlets'),
(314515, 222715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Gloves of the Tormented'),
(314515, 222716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Belt of Untapped Power'),
(314515, 222718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Blooddrenched Mask'),
(314515, 222720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Zulian Headdress'),
(314515, 222721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Band of Servitude'),
(314515, 222722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Arlokk (Ascended) - Seal of the Gurubashi Berserker'),
(314515, 60103, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Arlokk (Ascended) - Sigil of High Priestess Arlokk');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314517;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314517, 219915, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Zulian Defender'),
(314517, 219918, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Jeklik\'s Crusher'),
(314517, 219920, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Primalist\'s Band'),
(314517, 219923, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Jeklik\'s Opaline Talisman'),
(314517, 219928, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Animist\'s Spaulders'),
(314517, 220262, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Seafury Boots'),
(314517, 220265, 0, 0, 0, 1, 1, 1, 1, 'High Priestess Jeklik (Ascended) - Peacekeeper Boots'),
(314517, 222711, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Cloak of the Hakkari Worshippers'),
(314517, 222712, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Might of the Tribe'),
(314517, 222713, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Zulian Scepter of Rites'),
(314517, 222714, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Sacrificial Gauntlets'),
(314517, 222715, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Gloves of the Tormented'),
(314517, 222716, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Belt of Untapped Power'),
(314517, 222718, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Blooddrenched Mask'),
(314517, 222720, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Zulian Headdress'),
(314517, 222721, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Band of Servitude'),
(314517, 222722, 0, 0, 0, 1, 2, 1, 1, 'High Priestess Jeklik (Ascended) - Seal of the Gurubashi Berserker'),
(314517, 60104, 0, 1, 0, 1, 0, 1, 1, 'High Priestess Jeklik (Ascended) - Sigil of High Priestess Jeklik');

DELETE FROM `creature_loot_template` WHERE `Entry` = 314834;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(314834, 97725, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Ascended) - Offering Key'),
(314834, 219802, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Ascended) - Heart of Hakkar'),
(314834, 2500039, 0, 100, 0, 1, 0, 1, 1, 'Hakkar (Ascended) - Cache of the Blood God'),
(314834, 219852, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Ancient Hakkari Manslayer'),
(314834, 219853, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Gurubashi Dwarf Destroyer'),
(314834, 219854, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Zin\'rokh, Destroyer of Worlds'),
(314834, 219855, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Bloodsoaked Legplates'),
(314834, 219856, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - The Eye of Hakkar'),
(314834, 219857, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Cloak of Consumption'),
(314834, 219859, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Fang of the Faceless'),
(314834, 219861, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Touch of Chaos'),
(314834, 219862, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Aegis of the Blood God'),
(314834, 219864, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Bloodcaller'),
(314834, 219865, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Warblade of the Hakkari'),
(314834, 219876, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Soul Corrupter\'s Necklace'),
(314834, 220257, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Seafury Gauntlets'),
(314834, 220264, 0, 0, 0, 1, 1, 1, 1, 'Hakkar (Ascended) - Peacekeeper Gauntlets'),
(314834, 60108, 0, 1, 0, 1, 0, 1, 1, 'Hakkar (Ascended) - Sigil of Hakkar');

DELETE FROM `creature_loot_template` WHERE `Entry` = 315082;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(315082, 219951, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Gri\'lek\'s Charm of Might'),
(315082, 219952, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Gri\'lek\'s Charm of Valor'),
(315082, 219953, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Renataki\'s Charm of Beasts'),
(315082, 219954, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Renataki\'s Charm of Trickery'),
(315082, 219955, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Wushoolay\'s Charm of Nature'),
(315082, 219956, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Wushoolay\'s Charm of Spirits'),
(315082, 219957, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Hazza\'rah\'s Charm of Destruction'),
(315082, 219958, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Hazza\'rah\'s Charm of Healing'),
(315082, 219959, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Hazza\'rah\'s Charm of Magic'),
(315082, 219961, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Gri\'lek\'s Grinder'),
(315082, 219962, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Gri\'lek\'s Carver'),
(315082, 219963, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Pitchfork of Madness'),
(315082, 219964, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Renataki\'s Soul Conduit'),
(315082, 219965, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Wushoolay\'s Poker'),
(315082, 219967, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Thoughtblighter'),
(315082, 219968, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Fiery Retributer'),
(315082, 219993, 0, 11.111, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Hoodoo Hunting Bow'),
(315082, 60116, 0, 1, 0, 1, 0, 1, 1, 'Gri\'lek (Ascended) - Sigil of Gri\'lek');

DELETE FROM `creature_loot_template` WHERE `Entry` = 315083;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(315083, 219951, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Gri\'lek\'s Charm of Might'),
(315083, 219952, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Gri\'lek\'s Charm of Valor'),
(315083, 219953, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Renataki\'s Charm of Beasts'),
(315083, 219954, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Renataki\'s Charm of Trickery'),
(315083, 219955, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Wushoolay\'s Charm of Nature'),
(315083, 219956, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Wushoolay\'s Charm of Spirits'),
(315083, 219957, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Hazza\'rah\'s Charm of Destruction'),
(315083, 219958, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Hazza\'rah\'s Charm of Healing'),
(315083, 219959, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Hazza\'rah\'s Charm of Magic'),
(315083, 219961, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Gri\'lek\'s Grinder'),
(315083, 219962, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Gri\'lek\'s Carver'),
(315083, 219963, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Pitchfork of Madness'),
(315083, 219964, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Renataki\'s Soul Conduit'),
(315083, 219965, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Wushoolay\'s Poker'),
(315083, 219967, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Thoughtblighter'),
(315083, 219968, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Fiery Retributer'),
(315083, 219993, 0, 11.111, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Hoodoo Hunting Bow'),
(315083, 60117, 0, 1, 0, 1, 0, 1, 1, 'Hazza\'rah (Ascended) - Sigil of Hazza\'rah');

DELETE FROM `creature_loot_template` WHERE `Entry` = 315084;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(315084, 219951, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Gri\'lek\'s Charm of Might'),
(315084, 219952, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Gri\'lek\'s Charm of Valor'),
(315084, 219953, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Renataki\'s Charm of Beasts'),
(315084, 219954, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Renataki\'s Charm of Trickery'),
(315084, 219955, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Wushoolay\'s Charm of Nature'),
(315084, 219956, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Wushoolay\'s Charm of Spirits'),
(315084, 219957, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Hazza\'rah\'s Charm of Destruction'),
(315084, 219958, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Hazza\'rah\'s Charm of Healing'),
(315084, 219959, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Hazza\'rah\'s Charm of Magic'),
(315084, 219961, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Gri\'lek\'s Grinder'),
(315084, 219962, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Gri\'lek\'s Carver'),
(315084, 219963, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Pitchfork of Madness'),
(315084, 219964, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Renataki\'s Soul Conduit'),
(315084, 219965, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Wushoolay\'s Poker'),
(315084, 219967, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Thoughtblighter'),
(315084, 219968, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Fiery Retributer'),
(315084, 219993, 0, 11.111, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Hoodoo Hunting Bow'),
(315084, 60118, 0, 1, 0, 1, 0, 1, 1, 'Renataki (Ascended) - Sigil of Renataki');

DELETE FROM `creature_loot_template` WHERE `Entry` = 315085;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(315085, 219951, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Gri\'lek\'s Charm of Might'),
(315085, 219952, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Gri\'lek\'s Charm of Valor'),
(315085, 219953, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Renataki\'s Charm of Beasts'),
(315085, 219954, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Renataki\'s Charm of Trickery'),
(315085, 219955, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Wushoolay\'s Charm of Nature'),
(315085, 219956, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Wushoolay\'s Charm of Spirits'),
(315085, 219957, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Hazza\'rah\'s Charm of Destruction'),
(315085, 219958, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Hazza\'rah\'s Charm of Healing'),
(315085, 219959, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Hazza\'rah\'s Charm of Magic'),
(315085, 219961, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Gri\'lek\'s Grinder'),
(315085, 219962, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Gri\'lek\'s Carver'),
(315085, 219963, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Pitchfork of Madness'),
(315085, 219964, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Renataki\'s Soul Conduit'),
(315085, 219965, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Wushoolay\'s Poker'),
(315085, 219967, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Thoughtblighter'),
(315085, 219968, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Fiery Retributer'),
(315085, 219993, 0, 11.111, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Hoodoo Hunting Bow'),
(315085, 60119, 0, 1, 0, 1, 0, 1, 1, 'Wushoolay (Ascended) - Sigil of Wushoolay');

DELETE FROM `creature_loot_template` WHERE `Entry` = 315114;
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(315114, 219944, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Nat Pagle\'s Fish Terminator'),
(315114, 219945, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Foror\'s Eyepatch'),
(315114, 219946, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Tigule\'s Harpoon'),
(315114, 219947, 0, 20, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Nat Pagle\'s Broken Reel'),
(315114, 219908, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Sceptre of Smiting'),
(315114, 219921, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Zulian Hacker'),
(315114, 220258, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Zulian Ceremonial Staff'),
(315114, 220259, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Shadow Panther Hide Gloves'),
(315114, 220261, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Shadow Panther Hide Belt'),
(315114, 220263, 0, 0, 0, 1, 1, 1, 1, 'Gahz\'ranka (Ascended) - Gurubashi Helm'),
(315114, 1022739, 0, 10, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Tome of Polymorph: Turtle'),
(315114, 60120, 0, 1, 0, 1, 0, 1, 1, 'Gahz\'ranka (Ascended) - Sigil of Gahz\'ranka');
