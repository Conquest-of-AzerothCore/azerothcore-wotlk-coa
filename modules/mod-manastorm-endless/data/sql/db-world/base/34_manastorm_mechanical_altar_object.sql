-- Mechanical Mystic Altar (991572), item 2903513, missing object 245006.
-- The supplied client recognizes this exact entry in C_MysticEnchant's nearby
-- altar check. Native summoning retains the spell's five-minute lifetime.
-- Display 1029671 is a supplied Dalaran enchanting-workbench reconstruction;
-- the original Mechanical Altar display is not present in the supplied DB.
-- This restores the object/presence dependency ONLY. A Mystic Enchanting server
-- service is still required for reforging, extraction, collection and applying.
-- No ordinary profession-enchanting substitute or fabricated service is bound.
-- INSERT IGNORE intentionally preserves any existing upstream object.

INSERT IGNORE INTO `gameobject_template`
(`entry`, `type`, `displayId`, `name`, `size`, `VerifiedBuild`)
VALUES (245006, 10, 1029671, 'Mechanical Mystic Altar', 1, 0);
