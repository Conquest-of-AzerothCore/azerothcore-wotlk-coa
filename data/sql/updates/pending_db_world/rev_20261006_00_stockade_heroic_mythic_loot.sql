-- The Stockade on Heroic and Mythic: the bosses shared their Normal loot (cloth, potions, level 20 items), and only
-- Kam's Walking Stick and Bruegal's three items have Heroic/Mythic versions to swap in. Each Heroic/Mythic boss
-- now has its own loot: those versions (Kam's staff at 25 % as in the Exiles export), the boss sigil (1 %) and the
-- quest drops. The Normal loot list is gone from these difficulties.
DELETE FROM `creature_loot_template` WHERE `Entry` IN (101663, 101666, 101696, 101716, 101717, 101720, 201663, 201666, 201696, 201716, 201717, 201720);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(101663, 3628, 0, 100, 1, 1, 0, 1, 1, 'Dextren Ward (Heroic) - Hand of Dextren Ward'),
(101663, 2909, 0, 40, 1, 1, 0, 1, 1, 'Dextren Ward (Heroic) - Red Wool Bandana'),
(101663, 56969, 0, 1, 0, 1, 0, 1, 1, 'Dextren Ward (Heroic) - Sigil of Dextren Ward'),
(101666, 3640, 0, 100, 1, 1, 0, 1, 1, 'Kam Deepfury (Heroic) - Head of Deepfury'),
(101666, 1552280, 0, 25, 0, 1, 0, 1, 1, 'Kam Deepfury (Heroic) - Kam''s Walking Stick'),
(101666, 56970, 0, 1, 0, 1, 0, 1, 1, 'Kam Deepfury (Heroic) - Sigil of Kam Deepfury'),
(101696, 3630, 0, 100, 1, 1, 0, 1, 1, 'Targorr the Dread (Heroic) - Head of Targorr'),
(101696, 56971, 0, 1, 0, 1, 0, 1, 1, 'Targorr the Dread (Heroic) - Sigil of Targorr the Dread'),
(101716, 2926, 0, 100, 1, 1, 0, 1, 1, 'Bazil Thredd (Heroic) - Head of Bazil Thredd'),
(101716, 2909, 0, 80, 1, 1, 0, 1, 1, 'Bazil Thredd (Heroic) - Red Wool Bandana'),
(101716, 56972, 0, 1, 0, 1, 0, 1, 1, 'Bazil Thredd (Heroic) - Sigil of Bazil Thredd'),
(101717, 56973, 0, 1, 0, 1, 0, 1, 1, 'Hamhock (Heroic) - Sigil of Hamhock'),
(101720, 2909, 0, 80, 1, 1, 0, 1, 1, 'Bruegal Ironknuckle (Heroic) - Red Wool Bandana'),
(101720, 1553228, 0, 60, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Heroic) - Jimmied Handcuffs'),
(101720, 1552941, 0, 20, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Heroic) - Prison Shank'),
(101720, 1552942, 0, 20, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Heroic) - Iron Knuckles'),
(101720, 56974, 0, 1, 0, 1, 0, 1, 1, 'Bruegal Ironknuckle (Heroic) - Sigil of Bruegal Ironknuckle'),
(201663, 3628, 0, 100, 1, 1, 0, 1, 1, 'Dextren Ward (Mythic) - Hand of Dextren Ward'),
(201663, 2909, 0, 40, 1, 1, 0, 1, 1, 'Dextren Ward (Mythic) - Red Wool Bandana'),
(201663, 56969, 0, 1, 0, 1, 0, 1, 1, 'Dextren Ward (Mythic) - Sigil of Dextren Ward'),
(201666, 3640, 0, 100, 1, 1, 0, 1, 1, 'Kam Deepfury (Mythic) - Head of Deepfury'),
(201666, 1652280, 0, 25, 0, 1, 0, 1, 1, 'Kam Deepfury (Mythic) - Kam''s Walking Stick'),
(201666, 56970, 0, 1, 0, 1, 0, 1, 1, 'Kam Deepfury (Mythic) - Sigil of Kam Deepfury'),
(201696, 3630, 0, 100, 1, 1, 0, 1, 1, 'Targorr the Dread (Mythic) - Head of Targorr'),
(201696, 56971, 0, 1, 0, 1, 0, 1, 1, 'Targorr the Dread (Mythic) - Sigil of Targorr the Dread'),
(201716, 2926, 0, 100, 1, 1, 0, 1, 1, 'Bazil Thredd (Mythic) - Head of Bazil Thredd'),
(201716, 2909, 0, 80, 1, 1, 0, 1, 1, 'Bazil Thredd (Mythic) - Red Wool Bandana'),
(201716, 56972, 0, 1, 0, 1, 0, 1, 1, 'Bazil Thredd (Mythic) - Sigil of Bazil Thredd'),
(201717, 56973, 0, 1, 0, 1, 0, 1, 1, 'Hamhock (Mythic) - Sigil of Hamhock'),
(201720, 2909, 0, 80, 1, 1, 0, 1, 1, 'Bruegal Ironknuckle (Mythic) - Red Wool Bandana'),
(201720, 1653228, 0, 60, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Mythic) - Jimmied Handcuffs'),
(201720, 1652941, 0, 20, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Mythic) - Prison Shank'),
(201720, 1652942, 0, 20, 0, 1, 1, 1, 1, 'Bruegal Ironknuckle (Mythic) - Iron Knuckles'),
(201720, 56974, 0, 1, 0, 1, 0, 1, 1, 'Bruegal Ironknuckle (Mythic) - Sigil of Bruegal Ironknuckle');

UPDATE `creature_template` SET `lootid` = `entry` WHERE `entry` IN (101663, 101666, 101696, 101716, 101717, 101720, 201663, 201666, 201696, 201716, 201717, 201720);
