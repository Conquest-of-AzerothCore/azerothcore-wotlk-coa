-- Reaper tier set for Icecrown Citadel: Frostbitten Battleplate of the Risen Nightmare.
--
-- The Reaper is a plate class that scales off Strength, and Icecrown has no plate DPS tier it
-- can wear. This is that tier: five pieces at four item levels, cut from the live Sanctified
-- Scourgelord Battlegear budget (the Death Knight plate DPS tier of the same raid) rather than
-- from invented numbers, and scaled by item level along the curve the existing 264 and 277 tiers
-- already describe - 183/161 Strength across 13 item levels, 1.00988 per level.
--
-- Stats follow the class: Strength first, then Stamina, then two of critical strike, haste and
-- armor penetration per piece. Attack power is deliberately absent: a plate damage dealer already
-- turns Strength into attack power at 2 to 1, so a separate attack power line would pay twice for
-- the same stat and cost the budget that buys the ratings. Hit and expertise are absent for the
-- same reason the Scourgelord tier leaves them off - they are capped from elsewhere in the set.
--
-- The look is item set 1084, 'Frostbitten Raiment of the Risen Nightmare', which is what the
-- appearance items 884226-884235 already use. The helm is the exception: it takes display 76717,
-- the Crown of the Lich Lord, which is the Lich King's own crown and already in the client.

-- The two set bonuses, as three spells.
--
-- 2 pieces: Harvest Time's cooldown drops by 30 seconds, 180 -> 150. Expressed the way every
-- other cooldown bonus in this expansion is: SPELL_AURA_ADD_FLAT_MODIFIER (107) with
-- SPELLMOD_COOLDOWN (11), restricted to SpellFamilyName 36 and Harvest Time's own class mask
-- word, 0x4000000. EffectBasePoints is -30001 because the core adds one to the stored value.
--
-- 4 pieces: every Reaped Soul spent grants 5% Strength for 8 seconds, stacking to 3. 2990002 is
-- the marker the set applies and the module watches; 2990003 is the buff it hands out.
DELETE FROM `spell_dbc` WHERE `ID` IN (2990001, 2990002, 2990003);

INSERT INTO `spell_dbc` (`ID`, `Attributes`, `AttributesEx`, `DurationIndex`, `RangeIndex`, `SchoolMask`, `SpellLevel`, `Effect_1`, `EffectAura_1`, `EffectBasePoints_1`, `EffectDieSides_1`, `EffectMiscValue_1`, `ImplicitTargetA_1`, `EffectSpellClassMaskC_1`, `SpellClassSet`, `CumulativeAura`, `SpellIconID`, `Name_Lang_enUS`, `Description_Lang_enUS`, `AuraDescription_Lang_enUS`, `Name_Lang_Mask`, `Description_Lang_Mask`, `AuraDescription_Lang_Mask`) VALUES
(2990001, 268435648, 0, 21, 1, 1, 80, 6, 107, -30001, 1, 11, 1, 67108864, 36, 0, 26472,
 'Frostbitten Battleplate 2P Bonus',
 'Reduces the cooldown of your Harvest Time by 30 sec.',
 'Reduces the cooldown of your Harvest Time by 30 sec.', 16712190, 16712190, 16712190),
(2990002, 268435648, 0, 21, 1, 1, 80, 6, 4, 0, 1, 0, 1, 0, 36, 0, 26472,
 'Frostbitten Battleplate 4P Bonus',
 'Each Reaped Soul you consume increases your Strength by 5% for 8 sec. Stacks up to 3 times.',
 'Each Reaped Soul you consume increases your Strength by 5% for 8 sec. Stacks up to 3 times.', 16712190, 16712190, 16712190),
(2990003, 268435456, 0, 31, 1, 1, 80, 6, 137, 4, 1, 0, 1, 0, 36, 3, 26472,
 'Harvested Might',
 'Strength increased by 5%.',
 'Strength increased by 5%.', 16712190, 16712190, 16712190);

-- The twenty pieces.
DELETE FROM `item_template` WHERE `entry` BETWEEN 992001 AND 992099;

INSERT INTO `item_template`
  (`entry`, `class`, `subclass`, `name`, `displayid`, `Quality`, `Flags`, `InventoryType`,
   `AllowableClass`, `AllowableRace`, `ItemLevel`, `RequiredLevel`, `bonding`,
   `stat_type1`, `stat_value1`, `stat_type2`, `stat_value2`, `stat_type3`, `stat_value3`,
   `stat_type4`, `stat_value4`, `armor`, `Material`, `sheath`, `itemset`, `MaxDurability`,
   `socketColor_1`, `socketColor_2`, `socketBonus`, `DisenchantID`, `RequiredDisenchantSkill`)
VALUES
  (992001, 4, 6, 'Frostbitten Helm of the Risen Nightmare', 76717, 4, 0, 1, 536870912, -1, 251, 80, 1, 4, 142, 7, 163, 32, 88, 44, 81, 1486, 4, 0, 63001, 100, 1, 2, 3312, 68, 375),
  (992002, 4, 6, 'Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 251, 80, 1, 4, 113, 7, 121, 36, 70, 32, 63, 1371, 6, 0, 63001, 100, 2, 0, 2892, 68, 375),
  (992003, 4, 6, 'Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 251, 80, 1, 4, 149, 7, 163, 32, 95, 44, 81, 1830, 1, 0, 63001, 165, 2, 8, 3357, 68, 375),
  (992004, 4, 6, 'Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 251, 80, 1, 4, 149, 7, 163, 36, 95, 44, 81, 1601, 6, 0, 63001, 120, 4, 8, 3357, 68, 375),
  (992005, 4, 6, 'Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 251, 80, 1, 4, 113, 7, 121, 32, 70, 36, 63, 1144, 1, 0, 63001, 55, 4, 0, 2927, 68, 375),
  (992011, 4, 6, 'Sanctified Frostbitten Helm of the Risen Nightmare', 76717, 4, 0, 1, 536870912, -1, 264, 80, 1, 4, 161, 7, 185, 32, 100, 44, 92, 1689, 4, 0, 63002, 100, 1, 2, 3312, 68, 375),
  (992012, 4, 6, 'Sanctified Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 264, 80, 1, 4, 129, 7, 137, 36, 80, 32, 72, 1559, 6, 0, 63002, 100, 2, 0, 2892, 68, 375),
  (992013, 4, 6, 'Sanctified Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 264, 80, 1, 4, 169, 7, 185, 32, 108, 44, 92, 2080, 1, 0, 63002, 165, 2, 8, 3357, 68, 375),
  (992014, 4, 6, 'Sanctified Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 264, 80, 1, 4, 169, 7, 185, 36, 108, 44, 92, 1820, 6, 0, 63002, 120, 4, 8, 3357, 68, 375),
  (992015, 4, 6, 'Sanctified Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 264, 80, 1, 4, 129, 7, 137, 32, 80, 36, 72, 1300, 1, 0, 63002, 55, 4, 0, 2927, 68, 375),
  (992021, 4, 6, 'Mythic Frostbitten Helm of the Risen Nightmare', 76717, 4, 0, 1, 536870912, -1, 277, 80, 1, 4, 183, 7, 210, 32, 114, 44, 105, 1920, 4, 0, 63003, 100, 1, 2, 3312, 68, 375),
  (992022, 4, 6, 'Mythic Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 277, 80, 1, 4, 147, 7, 156, 36, 91, 32, 82, 1772, 6, 0, 63003, 100, 2, 0, 2892, 68, 375),
  (992023, 4, 6, 'Mythic Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 277, 80, 1, 4, 192, 7, 210, 32, 123, 44, 105, 2364, 1, 0, 63003, 165, 2, 8, 3357, 68, 375),
  (992024, 4, 6, 'Mythic Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 277, 80, 1, 4, 192, 7, 210, 36, 123, 44, 105, 2069, 6, 0, 63003, 120, 4, 8, 3357, 68, 375),
  (992025, 4, 6, 'Mythic Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 277, 80, 1, 4, 147, 7, 156, 32, 91, 36, 82, 1478, 1, 0, 63003, 55, 4, 0, 2927, 68, 375),
  (992031, 4, 6, 'Ascended Frostbitten Helm of the Risen Nightmare', 76717, 4, 0, 1, 536870912, -1, 284, 80, 1, 4, 196, 7, 225, 32, 122, 44, 112, 2055, 4, 0, 63004, 100, 1, 2, 3312, 68, 375),
  (992032, 4, 6, 'Ascended Frostbitten Pauldrons of the Risen Nightmare', 136807, 4, 0, 3, 536870912, -1, 284, 80, 1, 4, 157, 7, 167, 36, 97, 32, 88, 1897, 6, 0, 63004, 100, 2, 0, 2892, 68, 375),
  (992033, 4, 6, 'Ascended Frostbitten Breastplate of the Risen Nightmare', 136811, 4, 0, 5, 536870912, -1, 284, 80, 1, 4, 206, 7, 225, 32, 131, 44, 112, 2531, 1, 0, 63004, 165, 2, 8, 3357, 68, 375),
  (992034, 4, 6, 'Ascended Frostbitten Legplates of the Risen Nightmare', 136814, 4, 0, 7, 536870912, -1, 284, 80, 1, 4, 206, 7, 225, 36, 131, 44, 112, 2215, 6, 0, 63004, 120, 4, 8, 3357, 68, 375),
  (992035, 4, 6, 'Ascended Frostbitten Gauntlets of the Risen Nightmare', 136815, 4, 0, 10, 536870912, -1, 284, 80, 1, 4, 157, 7, 167, 32, 97, 36, 88, 1582, 1, 0, 63004, 55, 4, 0, 2927, 68, 375);

-- The four ItemSet rows. itemset_dbc is the server-side override the DBC loader reads; the
-- client needs the same rows in its own ItemSet.dbc before it will draw the bonus lines on the
-- tooltip, which is a separate client patch.
DELETE FROM `itemset_dbc` WHERE `ID` BETWEEN 63001 AND 63004;
INSERT INTO `itemset_dbc`
  (`ID`, `Name_Lang_enUS`, `Name_Lang_Mask`, `ItemID_1`, `ItemID_2`, `ItemID_3`, `ItemID_4`,
   `ItemID_5`, `SetSpellID_1`, `SetThreshold_1`, `SetSpellID_2`, `SetThreshold_2`,
   `RequiredSkill`, `RequiredSkillRank`)
VALUES
  (63001, 'Frostbitten Battleplate of the Risen Nightmare', 16712190, 992001, 992002, 992003, 992004, 992005, 2990001, 2, 2990002, 4, 0, 0),
  (63002, 'Sanctified Frostbitten Battleplate of the Risen Nightmare', 16712190, 992011, 992012, 992013, 992014, 992015, 2990001, 2, 2990002, 4, 0, 0),
  (63003, 'Mythic Frostbitten Battleplate of the Risen Nightmare', 16712190, 992021, 992022, 992023, 992024, 992025, 2990001, 2, 2990002, 4, 0, 0),
  (63004, 'Ascended Frostbitten Battleplate of the Risen Nightmare', 16712190, 992031, 992032, 992033, 992034, 992035, 2990001, 2, 2990002, 4, 0, 0);


-- item_set_names is what the tooltip reads for the "Frostbitten Battleplate (0/5)" line and for the
-- slot each piece counts as. Without a row the core logs a warning per item and falls back to the
-- item_template name, which would print the piece's own name where the set's belongs.
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
