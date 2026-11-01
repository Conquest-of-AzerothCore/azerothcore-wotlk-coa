-- Reaper tier pieces, restated from the live Ymirjar Lord's Battlegear rows.
--
-- Armor subclass is 4. In this client's ItemSubClassArmor, 4 is Plate and 6 is Shield - the first
-- pass used 6, so ItemTemplate::GetSkill returned SKILL_SHIELD and equipping failed with
-- EQUIP_ERR_NO_REQUIRED_PROFICIENCY. Every plate piece the character already wears is subclass 4.
--
-- The first pass scaled one reference item level by a curve, which put every piece one or two
-- points off the tier it sits beside - 183 Strength on the 277 helm where the Sanctified Ymirjar
-- Lord's Helmet of the same item level carries 185. Take the numbers instead of deriving them:
-- item set 895 already has this exact slot at 251, 264 and 277, so those three item levels are
-- copied straight out of item_template and match to the point.
--
--   251 -> 50080 50082 50078 50081 50079
--   264 -> 51212 51210 51214 51211 51213
--   277 -> 51227 51229 51225 51228 51226
--
-- 284 has no tier in this database to copy, so each slot continues its own 264 -> 277 slope for
-- seven more item levels. That is the only evidence available and it keeps the four tiers on one
-- line rather than on a curve invented for them.
--
-- The secondary stats are the reference's own: critical strike on every piece, armor penetration
-- on the helm, shoulders and chest, expertise on the legs and hit on the hands. Haste is absent
-- because this tier has none to copy - say the word and two of the armor penetration lines become
-- haste instead.
--
-- Helm display is 136808, the Frostbitten helm of the same set as the rest of the pieces. The
-- Lich King's Crown of Domination has no item model in 3.3.5 - it lives on the creature - so it
-- needs the model patch, which is still locked.

DELETE FROM `item_template` WHERE `entry` BETWEEN 992001 AND 992099;

INSERT INTO `item_template`
  (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `InventoryType`,
   `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `bonding`,
   `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`,
   `stat_type4`, `stat_value4`, `armor`, `Material`, `sheath`, `itemset`, `MaxDurability`,
   `socketColor_1`, `socketColor_2`, `socketBonus`, `DisenchantID`, `RequiredDisenchantSkill`)
VALUES
  (992001, 4, 4, 'Frostbitten Helm of the Risen Nightmare', 136808, 4, 0, 1, 536870912, -1, 251, 80, 1, 4, 140, 7, 164, 32, 88, 44, 80, 1616, 4, 0, 63001, 100, 1, 2, 3312, 68, 375),
  (992002, 4, 4, 'Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 251, 80, 1, 4, 114, 7, 122, 32, 71, 44, 63, 1492, 6, 0, 63001, 100, 2, 0, 2892, 68, 375),
  (992003, 4, 4, 'Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 251, 80, 1, 4, 148, 7, 164, 32, 96, 44, 80, 1990, 1, 0, 63001, 165, 2, 8, 3357, 68, 375),
  (992004, 4, 4, 'Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 251, 80, 1, 4, 148, 7, 163, 32, 96, 37, 80, 1741, 6, 0, 63001, 120, 4, 8, 3357, 68, 375),
  (992005, 4, 4, 'Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 251, 80, 1, 4, 114, 7, 122, 32, 71, 31, 63, 1243, 1, 0, 63001, 55, 4, 0, 2927, 68, 375),
  (992011, 4, 4, 'Sanctified Frostbitten Helm of the Risen Nightmare', 136808, 4, 0, 1, 536870912, -1, 264, 80, 1, 4, 161, 7, 185, 32, 100, 44, 92, 1689, 4, 0, 63002, 100, 1, 2, 3312, 68, 375),
  (992012, 4, 4, 'Sanctified Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 264, 80, 1, 4, 129, 7, 137, 32, 80, 44, 72, 1559, 6, 0, 63002, 100, 2, 0, 2892, 68, 375),
  (992013, 4, 4, 'Sanctified Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 264, 80, 1, 4, 169, 7, 185, 32, 108, 44, 92, 2080, 1, 0, 63002, 165, 2, 8, 3357, 68, 375),
  (992014, 4, 4, 'Sanctified Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 264, 80, 1, 4, 169, 7, 184, 32, 108, 37, 92, 1820, 6, 0, 63002, 120, 4, 8, 3357, 68, 375),
  (992015, 4, 4, 'Sanctified Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 264, 80, 1, 4, 129, 7, 137, 32, 80, 31, 72, 1300, 1, 0, 63002, 55, 4, 0, 2927, 68, 375),
  (992021, 4, 4, 'Mythic Frostbitten Helm of the Risen Nightmare', 136808, 4, 0, 1, 536870912, -1, 277, 80, 1, 4, 185, 7, 209, 32, 114, 44, 106, 1763, 4, 0, 63003, 100, 1, 2, 3312, 68, 375),
  (992022, 4, 4, 'Mythic Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 277, 80, 1, 4, 147, 7, 155, 32, 90, 44, 82, 1628, 6, 0, 63003, 100, 2, 0, 2892, 68, 375),
  (992023, 4, 4, 'Mythic Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 277, 80, 1, 4, 193, 7, 209, 32, 122, 44, 106, 2170, 1, 0, 63003, 165, 2, 8, 3357, 68, 375),
  (992024, 4, 4, 'Mythic Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 277, 80, 1, 4, 193, 7, 208, 32, 122, 37, 106, 1899, 6, 0, 63003, 120, 4, 8, 3357, 68, 375),
  (992025, 4, 4, 'Mythic Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 277, 80, 1, 4, 147, 7, 155, 32, 90, 31, 82, 1357, 1, 0, 63003, 55, 4, 0, 2927, 68, 375),
  (992031, 4, 4, 'Ascended Frostbitten Helm of the Risen Nightmare', 136808, 4, 0, 1, 536870912, -1, 284, 80, 1, 4, 198, 7, 222, 32, 122, 44, 114, 1803, 4, 0, 63004, 100, 1, 2, 3312, 68, 375),
  (992032, 4, 4, 'Ascended Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 284, 80, 1, 4, 157, 7, 165, 32, 95, 44, 87, 1665, 6, 0, 63004, 100, 2, 0, 2892, 68, 375),
  (992033, 4, 4, 'Ascended Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 284, 80, 1, 4, 206, 7, 222, 32, 130, 44, 114, 2218, 1, 0, 63004, 165, 2, 8, 3357, 68, 375),
  (992034, 4, 4, 'Ascended Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 284, 80, 1, 4, 206, 7, 221, 32, 130, 37, 114, 1942, 6, 0, 63004, 120, 4, 8, 3357, 68, 375),
  (992035, 4, 4, 'Ascended Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 284, 80, 1, 4, 157, 7, 165, 32, 95, 31, 87, 1388, 1, 0, 63004, 55, 4, 0, 2927, 68, 375);

-- item_set_names is what the tooltip reads for the set line and the slot each piece counts as.
DELETE FROM `item_set_names` WHERE `entry` BETWEEN 992001 AND 992099;
INSERT INTO `item_set_names` (`entry`, `name`, `InventoryType`)
SELECT `it`.`entry`,
       CASE `it`.`itemset`
           WHEN 63001 THEN 'Frostbitten Battleplate of the Risen Nightmare'
           WHEN 63002 THEN 'Sanctified Frostbitten Battleplate of the Risen Nightmare'
           WHEN 63003 THEN 'Mythic Frostbitten Battleplate of the Risen Nightmare'
           ELSE 'Ascended Frostbitten Battleplate of the Risen Nightmare'
       END,
       `it`.`InventoryType`
FROM `item_template` AS `it`
WHERE `it`.`entry` BETWEEN 992001 AND 992099;
