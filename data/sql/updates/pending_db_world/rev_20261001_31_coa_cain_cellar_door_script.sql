-- The Cain manor cellar door 2300524 opens when a player holding the Repaired Cellar Key 559141 clicks it (CoA
-- footage). The CoA client builds that key from its own item data, which has no use spell, so a key lock can never
-- be opened from the client: it answers "The door is locked." without asking the server. The door therefore
-- carries no lock (Data1 0, flags 32 = no despawn) and go_coa_cain_cellar_door decides: it opens for a key holder
-- and tells anyone else the door is locked.
UPDATE `gameobject_template` SET `Data1` = 0, `ScriptName` = 'go_coa_cain_cellar_door' WHERE `entry` = 2300524;
UPDATE `gameobject_template_addon` SET `flags` = 32 WHERE `entry` = 2300524;
