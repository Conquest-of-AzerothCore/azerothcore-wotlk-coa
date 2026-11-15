-- Scarlet Lieutenant's Legplates (#9854): item 4050846 is named "Scrlet Lieutenant's Legplates"; its siblings
-- 4050843 to 4050850 read "Scarlet Lieutenant's ...".
UPDATE `item_template` SET `name` = 'Scarlet Lieutenant''s Legplates' WHERE `entry` = 4050846 AND `name` = 'Scrlet Lieutenant''s Legplates';
