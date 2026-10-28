-- Scholomance bosses sharing the rare pool reference 35031 rolled it at only 30-60%, so most kills dropped no rare.
-- Classic era observations (Wowhead Classic) give these bosses a rare on 77-93% of kills, and the AscensionDB archive
-- (rev d6494ceb3150, built 2026-09-12, Exiles DB) lists every pool item at ~2.8% for all six, a 75% pool roll.
UPDATE `creature_loot_template` SET `Chance` = 75
WHERE `Reference` = 35031 AND `Entry` IN (10502, 10504, 10505, 10507, 10901, 11261);
