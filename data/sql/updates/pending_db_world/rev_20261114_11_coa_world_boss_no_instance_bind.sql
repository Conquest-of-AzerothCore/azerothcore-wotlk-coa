-- World bosses pay and lock players themselves on the kill; the core's instance bind flag locked them first,
-- so they got nothing. Atal'zul's was already cleared.
UPDATE `creature_template` SET `flags_extra` = `flags_extra` & ~1
  WHERE `entry` IN (64600, 64601, 64604, 64605, 978080, 64627);
