-- Apex Huntmasters: Alliance name change.
-- "Huntmaster" stays the subtitle; the personal name is Torvald Greyfeather.

START TRANSACTION;

UPDATE `creature_template`
   SET `name` = 'Torvald Greyfeather', `subname` = 'Huntmaster'
 WHERE `entry` = 9916111;

COMMIT;
