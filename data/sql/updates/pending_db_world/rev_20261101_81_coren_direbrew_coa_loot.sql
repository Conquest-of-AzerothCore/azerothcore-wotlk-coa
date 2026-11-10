-- Live CoA drops its own level-60 Coren Direbrew loot instead of the stock guaranteed level-80 trinket
-- (reference 34284) (SUB creature_loot, 2026-10-04; client AtlasLoot corenCLASSIC): the six trinkets at 1.667%,
-- Direbrew's Shanker and Tankard O' Terror at 5%.
DELETE FROM `creature_loot_template` WHERE `Entry` = 23872 AND `Reference` = 34284;
DELETE FROM `creature_loot_template` WHERE `Entry` = 23872
    AND `Item` IN (2037127, 2037128, 2037597, 2038287, 2038288, 2038289, 2038290, 2048663);
INSERT INTO `creature_loot_template`
(`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`,
`Comment`) VALUES
(23872, 2037127, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Brightbrew Charm'),
(23872, 2037128, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Balebrew Charm'),
(23872, 2037597, 0, 5, 0, 1, 0, 1, 1, 'Coren Direbrew - Direbrew''s Shanker'),
(23872, 2038287, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Empty Mug of Direbrew'),
(23872, 2038288, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Direbrew Hops'),
(23872, 2038289, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Coren''s Lucky Coin'),
(23872, 2038290, 0, 1.667, 0, 1, 0, 1, 1, 'Coren Direbrew - Dark Iron Smoking Pipe'),
(23872, 2048663, 0, 5, 0, 1, 0, 1, 1, 'Coren Direbrew - Tankard O'' Terror');
