-- Spirit of Life (840002), summoned by Primordial Earth (806536 -> 572853) and Eternally Chosen
-- (802888 -> 572826), uses display 8824 (CreatureDisplayInfo.dbc Scale = 2.5, ModelID 141 Ent.mdx
-- height ~3.43 model units), rendering ~8.58 units tall at DisplayScale = 1 (#12469).
-- Setting DisplayScale = 0.4 normalizes display 8824 to effective scale 1.0 (~3.43 units, matching
-- player-summoned Treant 1964 display 18922 on the same ModelID 141) without changing shared
-- display or model-info rows used by world creature 9601 (Treant Spirit).
UPDATE `creature_template_model`
SET `DisplayScale` = 0.4
WHERE `CreatureID` = 840002
  AND `Idx` = 0
  AND `CreatureDisplayID` = 8824;
