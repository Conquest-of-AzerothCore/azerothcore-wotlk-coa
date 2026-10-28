-- Lava Core (17011) halved on every dropper and difficulty at the player's request (rate was too high):
-- each value is half of the Wowhead Classic rate set in rev_20261001_82. Explicit values keep the file idempotent.
UPDATE `creature_loot_template` SET `Chance` = 13.2396 WHERE `Item` = 17011 AND `Entry` IN (11659, 111659, 211659, 311659);
UPDATE `creature_loot_template` SET `Chance` = 19.1279 WHERE `Item` = 17011 AND `Entry` IN (11665, 111665, 211665, 311665);
UPDATE `creature_loot_template` SET `Chance` = 6.7295 WHERE `Item` = 17011 AND `Entry` IN (11666, 111666, 211666, 311666);
UPDATE `creature_loot_template` SET `Chance` = 6.71 WHERE `Item` = 17011 AND `Entry` IN (11667, 111667, 211667, 311667);
UPDATE `creature_loot_template` SET `Chance` = 4.9235 WHERE `Item` = 17011 AND `Entry` IN (11668, 111668, 211668, 311668);
UPDATE `creature_loot_template` SET `Chance` = 43.7412 WHERE `Item` = 17011 AND `Entry` IN (11988, 111988, 211988, 311988);
UPDATE `creature_loot_template` SET `Chance` = 36.4498 WHERE `Item` = 17011 AND `Entry` IN (12057, 112057, 212057, 312057);
UPDATE `creature_loot_template` SET `Chance` = 28.1041 WHERE `Item` = 17011 AND `Entry` IN (12076, 112076, 212076, 312076);
UPDATE `creature_loot_template` SET `Chance` = 27.8473 WHERE `Item` = 17011 AND `Entry` IN (12100, 112100, 212100, 312100);
UPDATE `creature_loot_template` SET `Chance` = 5.1678 WHERE `Item` = 17011 AND `Entry` IN (12101, 112101, 212101, 312101);
