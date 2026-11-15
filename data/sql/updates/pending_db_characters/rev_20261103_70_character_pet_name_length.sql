-- A tamed pet is saved under its creature family's name until it is renamed. Eleven of Ascension's families have
-- names longer than 21 characters (the longest, "Dinomancy Devilsaur DEPRECATED", has 30): "Man'ari Eredar (Purple)",
-- "Unbound Water Elemental", "Netherwing Proto-dragon" and others. Under strict SQL mode their save failed, so such a
-- pet vanished at the next login. Player-chosen names keep their own 12-character limit.
ALTER TABLE `character_pet` MODIFY COLUMN `name` VARCHAR(32) NOT NULL DEFAULT 'Pet';
