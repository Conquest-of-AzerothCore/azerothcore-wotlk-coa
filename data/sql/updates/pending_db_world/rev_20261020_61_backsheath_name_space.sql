-- Backsheath item copies were named "Name(Backsheath)" (65 items, e.g. Calamity's End 5553123) or "Name  (Backsheath)"
-- (Anima-Siphoning Sword 1777134) instead of "Name (Backsheath)".
UPDATE `item_template` SET `name` = REPLACE(`name`, '(Backsheath)', ' (Backsheath)')
WHERE `name` LIKE '_%(Backsheath)%' AND `name` NOT LIKE '% (Backsheath)%';
UPDATE `item_template` SET `name` = REPLACE(`name`, '  (Backsheath)', ' (Backsheath)') WHERE `name` LIKE '%  (Backsheath)%';
