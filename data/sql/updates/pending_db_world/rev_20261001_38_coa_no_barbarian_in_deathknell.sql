-- Deathknell has no Barbarian on CoA. rev_20260923_09 added one: Alessia 502951 as trainer, the letter
-- "Grave-Etched Tablet" 9302412 from Shadow Priest Sarvis and the trial "Welcome to the Warband" 9302413 with
-- its target Mortimer 9300257, all INFERRED. CoA's letter block for Deathknell (53000-53017) has no Barbarian
-- letter, and its five "Welcome to the Warband" quests (200104-200108: Gerald, Kali, Alanor, Gok, Jediyah) have
-- no Deathknell copy. The spawns and quest relations go; the templates stay unreferenced.
DELETE FROM `creature` WHERE (`guid`, `id`) IN ((9003719, 502951), (9003729, 9300257));
DELETE FROM `creature_queststarter` WHERE (`id`, `quest`) IN ((1569, 9302412), (502951, 9302413));
DELETE FROM `creature_questender` WHERE `id` = 502951 AND `quest` IN (9302412, 9302413);
