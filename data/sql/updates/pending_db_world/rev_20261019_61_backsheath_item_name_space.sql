-- CoA: 65 backsheath weapon copies are named 'Name(Backsheath)' while the other 325 read 'Name (Backsheath)'.
-- The missing space comes from the Ascension data itself; give them the same separator as the rest.
UPDATE `item_template` SET `name` = REPLACE(`name`, '(Backsheath)', ' (Backsheath)')
WHERE `name` LIKE '%_(Backsheath)%' AND `name` NOT LIKE '% (Backsheath)%';
