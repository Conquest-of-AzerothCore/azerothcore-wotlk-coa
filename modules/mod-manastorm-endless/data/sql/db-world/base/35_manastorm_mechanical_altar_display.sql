-- Correct the replacement display assigned by SQL 34 to Mechanical Mystic Altar.
-- Entry 245006 remains the native summon target and client-recognized altar.
-- Display 7355 references the standard Human Altar01 model in the supplied DBC.
-- This is a replacement appearance, not a claim about Ascension's original model.
-- Only replace our earlier display; preserve different upstream models and scripts.
-- Client interaction and the separately implemented enchanting backend require
-- an in-game test after applying this update and restarting the worldserver.

UPDATE `gameobject_template` SET `displayId` = 7355
WHERE `entry` = 245006 AND `type` = 10 AND `displayId` = 1029671
AND `ScriptName` = '' AND `AIName` = '';
