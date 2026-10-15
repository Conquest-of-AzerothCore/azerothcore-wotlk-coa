-- On Ascension, Champion's Hall and the Hall of Legends sell PvP gear only through the Season 1 vendors of
-- rev_20261008_02 and _03. Remove the other quartermasters of both halls: the Legacy Armor and Legacy Weapon
-- quartermasters (Sergeant Major Clate, Lieutenant Jackspring, First Sergeant Hola'mahi, Stone Guard Zarg), the
-- Accessories quartermasters (Master Sergeant Biggins, Brave Stonehide) and the Jewelcrafting quartermasters
-- (Captain O'Neal, Lady Palanseer). Their templates and vendor lists stay.
DELETE FROM `creature_addon` WHERE `guid` IN (SELECT `guid` FROM `creature` WHERE `id` IN (12781, 12784, 12785,
12793, 12794, 12795, 34043, 34081));
DELETE FROM `game_event_creature` WHERE `guid` IN (SELECT `guid` FROM `creature` WHERE `id` IN (12781, 12784, 12785,
12793, 12794, 12795, 34043, 34081));
DELETE FROM `creature` WHERE `id` IN (12781, 12784, 12785, 12793, 12794, 12795, 34043, 34081);
